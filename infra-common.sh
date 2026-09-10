#!/bin/bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${ROOT_DIR}/terraform"

CLUSTER_NAME="${CLUSTER_NAME:-elkony-cluster}"
EXTERNAL_DNS_ENABLED="${EXTERNAL_DNS_ENABLED:-true}"
EXTERNAL_DNS_HOSTED_ZONE_ID="${EXTERNAL_DNS_HOSTED_ZONE_ID:-Z08854981YJMPOX3Z1L}"

set_tf_vars() {
  TF_VARS=(
    -var="cluster_name=${CLUSTER_NAME}"
    -var="external_dns_enabled=${EXTERNAL_DNS_ENABLED}"
    -var="external_dns_hosted_zone_ids=[\"${EXTERNAL_DNS_HOSTED_ZONE_ID}\"]"
  )
}
