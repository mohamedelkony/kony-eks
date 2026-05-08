#!/bin/bash
set -euo pipefail

cd terraform
terraform init

CLUSTER_NAME="${CLUSTER_NAME:-elkony-cluster}"
EXTERNAL_DNS_ENABLED="${EXTERNAL_DNS_ENABLED:-true}"
EXTERNAL_DNS_HOSTED_ZONE_ID="${EXTERNAL_DNS_HOSTED_ZONE_ID:-Z08854981YJMPOX3Z1L}"

terraform apply \
  -var="cluster_name=${CLUSTER_NAME}" \
  -var="external_dns_enabled=${EXTERNAL_DNS_ENABLED}" \
  -var="external_dns_hosted_zone_ids=[\"${EXTERNAL_DNS_HOSTED_ZONE_ID}\"]" \
  -auto-approve

aws eks \
  update-kubeconfig \
  --name "$CLUSTER_NAME"

echo "Kubeconfig updated successfully."

kubectl apply -k ./manifests/base-application
