#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${ROOT_DIR}/terraform"

log() {
  echo "[destroy] $*"
}

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required but not installed."
  exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI is required but not installed."
  exit 1
fi

cd "${TF_DIR}"

cluster_name="${CLUSTER_NAME:-${TF_VAR_cluster_name:-}}"
if [[ -z "${cluster_name}" ]]; then
  cluster_name="$(terraform state show module.eks.aws_eks_cluster.this[0] 2>/dev/null | awk -F' = ' '/^[[:space:]]+name[[:space:]]+= / { gsub(/"/, "", $2); print $2; exit }')"
fi
if [[ -z "${cluster_name}" ]]; then
  cluster_name="elkony-cluster"
fi
log "Cluster name: ${cluster_name}"

terraform_destroy() {
  terraform destroy \
    -var="cluster_name=${cluster_name}" \
    --auto-approve
}

# Capture Terraform-managed EIPs before destroy for post-cleanup checks.
declare -a tf_eips=()
while IFS= read -r addr; do
  alloc_id="$(terraform state show "${addr}" 2>/dev/null | awk -F' = ' '/^id = / { gsub(/"/, "", $2); print $2; exit }')"
  if [[ -n "${alloc_id}" ]]; then
    tf_eips+=("${alloc_id}")
  fi
done < <(terraform state list 2>/dev/null | rg '(^|\\.)aws_eip\\.' || true)

# Best-effort Kubernetes cleanup to let AWS load balancers/EIPs drain before cluster teardown.
if command -v kubectl >/dev/null 2>&1 && kubectl version --request-timeout=5s >/dev/null 2>&1; then
  log "Deleting ingress resources (best-effort)"
  while read -r ns name; do
    [[ -z "${ns}" || -z "${name}" ]] && continue
    kubectl -n "${ns}" delete ingress "${name}" --ignore-not-found --wait=true >/dev/null 2>&1 || true
  done < <(kubectl get ingress -A --no-headers 2>/dev/null | awk '{print $1, $2}')

  log "Deleting LoadBalancer services (best-effort)"
  while read -r ns name; do
    [[ -z "${ns}" || -z "${name}" ]] && continue
    kubectl -n "${ns}" delete service "${name}" --ignore-not-found --wait=true >/dev/null 2>&1 || true
  done < <(kubectl get svc -A --field-selector spec.type=LoadBalancer --no-headers 2>/dev/null | awk '{print $1, $2}')
else
  log "kubectl is unavailable or cluster is unreachable, skipping Kubernetes pre-cleanup"
fi

# First attempt: normal destroy.
if ! terraform_destroy; then
  log "Destroy failed. Removing Kubernetes/Helm resources from state and retrying."
  terraform state rm \
    kubernetes_service_account_v1.cluster_autoscaler \
    helm_release.cluster_autoscaler \
    kubernetes_service_account_v1.aws_load_balancer_controller \
    helm_release.aws_load_balancer_controller \
    'kubernetes_service_account_v1.external_dns[0]' \
    'helm_release.external_dns[0]' >/dev/null 2>&1 || true
  terraform_destroy
fi

AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null || true)}}"
if [[ -z "${AWS_REGION}" ]]; then
  AWS_REGION="us-west-1"
  log "AWS region not set, defaulting to ${AWS_REGION}"
fi

declare -A eips_to_release=()
for alloc_id in "${tf_eips[@]}"; do
  eips_to_release["${alloc_id}"]=1
done

# Best-effort discovery of residual cluster-related EIPs (including AWS LB Controller artifacts).
while read -r alloc_id; do
  [[ -z "${alloc_id}" ]] && continue
  eips_to_release["${alloc_id}"]=1
done < <(
  aws ec2 describe-addresses \
    --region "${AWS_REGION}" \
    --filters "Name=tag:elbv2.k8s.aws/cluster,Values=${cluster_name}" \
    --query 'Addresses[?AssociationId==`null`].AllocationId' \
    --output text 2>/dev/null | tr '\t' '\n'
)

while read -r alloc_id; do
  [[ -z "${alloc_id}" ]] && continue
  eips_to_release["${alloc_id}"]=1
done < <(
  aws ec2 describe-addresses \
    --region "${AWS_REGION}" \
    --filters "Name=tag:kubernetes.io/cluster/${cluster_name},Values=owned,shared" \
    --query 'Addresses[?AssociationId==`null`].AllocationId' \
    --output text 2>/dev/null | tr '\t' '\n'
)

while read -r alloc_id; do
  [[ -z "${alloc_id}" ]] && continue
  eips_to_release["${alloc_id}"]=1
done < <(
  aws ec2 describe-addresses \
    --region "${AWS_REGION}" \
    --filters "Name=tag:created-by,Values=elkony" \
    --query 'Addresses[?AssociationId==`null`].AllocationId' \
    --output text 2>/dev/null | tr '\t' '\n'
)

for alloc_id in "${!eips_to_release[@]}"; do
  assoc_id="$(aws ec2 describe-addresses --region "${AWS_REGION}" --allocation-ids "${alloc_id}" --query 'Addresses[0].AssociationId' --output text 2>/dev/null || true)"
  if [[ "${assoc_id}" == "None" || "${assoc_id}" == "null" || -z "${assoc_id}" ]]; then
    log "Releasing residual EIP ${alloc_id}"
    aws ec2 release-address --region "${AWS_REGION}" --allocation-id "${alloc_id}" >/dev/null 2>&1 || true
  fi
done

log "Infrastructure destroy and residual EIP cleanup completed."
