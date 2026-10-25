#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/infra-common.sh"

aws eks \
  update-kubeconfig \
  --name "$CLUSTER_NAME"

echo "Kubeconfig updated successfully."

flux check --pre

NETRC_FILE="${NETRC_FILE:-${HOME}/.netrc}"

read_github_token_from_netrc() {
  if [[ ! -r "${NETRC_FILE}" ]]; then
    echo "Readable netrc file not found: ${NETRC_FILE}" >&2
    return 1
  fi

  awk '
    $1 == "machine" { in_github = ($2 == "github.com"); next }
    in_github && $1 == "password" { print $2; exit }
  ' "${NETRC_FILE}"
}

if kubectl get namespace flux-system >/dev/null 2>&1; then
  flux reconcile kustomization flux-system --with-source
  echo "Flux is already bootstrapped; reconciliation requested."
else
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    GITHUB_TOKEN="$(read_github_token_from_netrc)"
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
