#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/infra-common.sh"

MODE="${1:-pause}"

if [[ "${MODE}" != "pause" && "${MODE}" != "resume" ]]; then
  echo "Usage: $0 [pause|resume]"
  exit 1
fi

if [[ "${MODE}" == "pause" ]]; then
  set_tf_vars true
else
  set_tf_vars false
fi

cd "${TF_DIR}"
terraform init

terraform apply "${TF_VARS[@]}" -auto-approve

echo "Cluster ${MODE} completed."
