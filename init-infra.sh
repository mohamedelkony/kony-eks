#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/infra-common.sh"
set_tf_vars

cd "${TF_DIR}"
terraform init

terraform plan "${TF_VARS[@]}"

echo "Plan completed successfully. Applying changes..."

terraform apply "${TF_VARS[@]}" -auto-approve

echo "Infrastructure applied successfully."

aws eks \
  update-kubeconfig \
  --name "$CLUSTER_NAME"

echo "Kubeconfig updated successfully."

kubectl apply -k "${ROOT_DIR}/manifests/base-application"

echo "Base application manifests applied successfully."
