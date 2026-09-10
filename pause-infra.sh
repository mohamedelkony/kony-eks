#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/infra-common.sh"

MODE="${1:-pause}"
echo "Running cluster ${MODE}..."
if [[ "${MODE}" != "pause" && "${MODE}" != "resume" ]]; then
  echo "Usage: $0 [pause|resume]"
  exit 1
fi

if [[ "${MODE}" == "pause" ]]; then
  AUTOSCALER_REPLICAS=0
  DESIRED_SIZE=0
else
  AUTOSCALER_REPLICAS=1
  DESIRED_SIZE=1
fi

if [[ "${MODE}" == "pause" ]]; then
  echo "Scaling down cluster-autoscaler to 0 replicas..."
  kubectl scale deployment cluster-autoscaler -n kube-system --replicas=0 || true
fi

for NODE_GROUP in $(aws eks list-nodegroups --cluster-name "${CLUSTER_NAME}" --query 'nodegroups[]' --output text); do
  MAX_SIZE="$(aws eks describe-nodegroup \
    --cluster-name "${CLUSTER_NAME}" \
    --nodegroup-name "${NODE_GROUP}" \
    --query 'nodegroup.scalingConfig.maxSize' \
    --output text)"

  echo "Setting ${NODE_GROUP} desired size to ${DESIRED_SIZE}"

  aws eks update-nodegroup-config \
    --cluster-name "${CLUSTER_NAME}" \
    --nodegroup-name "${NODE_GROUP}" \
    --scaling-config "minSize=0,maxSize=${MAX_SIZE},desiredSize=${DESIRED_SIZE}" \
    >/dev/null

  aws eks wait nodegroup-active \
    --cluster-name "${CLUSTER_NAME}" \
    --nodegroup-name "${NODE_GROUP}"
done

if [[ "${MODE}" == "resume" ]]; then
  kubectl scale deployment cluster-autoscaler-aws-cluster-autoscaler -n kube-system --replicas="${AUTOSCALER_REPLICAS}"
fi

echo "Cluster ${MODE} completed."
