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

flux check --pre

if kubectl get namespace flux-system >/dev/null 2>&1; then
  flux reconcile kustomization flux-system --with-source
  echo "Flux is already bootstrapped; reconciliation requested."
else
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    if [[ ! -t 0 ]]; then
      echo "GITHUB_TOKEN is required to bootstrap Flux in a non-interactive shell." >&2
      exit 1
    fi

    read -r -s -p "GitHub token: " GITHUB_TOKEN
    echo
    export GITHUB_TOKEN
  fi

  if [[ -z "${GITHUB_TOKEN}" ]]; then
    echo "GitHub token cannot be empty." >&2
    exit 1
  fi

  flux bootstrap github \
    --owner=mohamedelkony \
    --repository=kony-eks \
    --branch=main \
    --path=clusters/dev \
    --personal

  echo "Flux bootstrapped successfully."
fi
