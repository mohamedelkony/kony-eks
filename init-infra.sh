#!/bin/bash
set -euo pipefail

cd terraform
terraform init

CLUSTER_NAME="elkony-cluster"

terraform apply \
  -var="cluster_name=${CLUSTER_NAME}" \
  -auto-approve

aws eks \
  update-kubeconfig \
  --name "$CLUSTER_NAME"

echo "Kubeconfig updated successfully."
