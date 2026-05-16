#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/infra-common.sh"

kubectl apply -k "${ROOT_DIR}/manifests/base-application"
