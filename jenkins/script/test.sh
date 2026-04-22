#!/usr/bin/env bash
set -euo pipefail

# Usage: test.sh <env>
ENV="${1:?Usage: test.sh <env>}"

echo "=== [test] Verifying VPC exists for env: ${ENV} ==="

VPC_IDS=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Environment,Values=${ENV}" \
  --query "Vpcs[*].VpcId" \
  --output text)

if [[ -z "${VPC_IDS}" ]]; then
  echo "ERROR: No VPC found with tag Environment=${ENV}"
  exit 1
fi

echo "OK: VPC(s) found for env '${ENV}': ${VPC_IDS}"
