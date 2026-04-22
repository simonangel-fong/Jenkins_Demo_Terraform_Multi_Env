#!/usr/bin/env bash
set -euo pipefail

# Usage: deploy.sh <env>
ENV="${1:?Usage: deploy.sh <env>}"
INFRA_DIR="infra"
VAR_FILE="${INFRA_DIR}/env/${ENV}/terraform.tfvars"
BACKEND_FILE="${INFRA_DIR}/env/${ENV}/backend.hcl"
PLAN_BINARY="tfplan.binary"
PLAN_TEXT="tfplan.txt"

cd "${INFRA_DIR}"

echo "=== [fmt] ==="
terraform fmt -recursive -check

echo "=== [init] ==="
terraform init -backend-config="../${BACKEND_FILE}" -reconfigure

echo "=== [validate] ==="
terraform validate

echo "=== [scan] ==="
trivy config --severity HIGH,CRITICAL --exit-code 1 .

echo "=== [plan] ==="
terraform plan \
  -var-file="../${VAR_FILE}" \
  -out="${PLAN_BINARY}" \
  -input=false
terraform show -no-color "${PLAN_BINARY}" > "${PLAN_TEXT}"

echo "=== [apply] ==="
terraform apply -input=false -auto-approve "${PLAN_BINARY}"
