#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

VALIDATOR="scripts/ci/terraform-validate-root.sh"
STACK_ROOT="terraform/stacks"
STACKS=(persistent platform identity remote-access recovery client-vpn-ad-poc)

if [ ! -x "$VALIDATOR" ]; then
  echo "ERROR: Terraform validation helper is missing or not executable: $VALIDATOR"
  exit 1
fi

echo "============================================================"
echo "Active Terraform lifecycle-stack validation"
echo "============================================================"

for stack in "${STACKS[@]}"; do
  root="$STACK_ROOT/$stack"

  if [ ! -d "$root" ]; then
    echo "ERROR: Required lifecycle stack is missing: $root"
    exit 1
  fi

  "$VALIDATOR" "$root"
done

echo
echo "============================================================"
echo "ALL ACTIVE LIFECYCLE STACK VALIDATIONS PASSED"
echo "Validated stacks: ${#STACKS[@]}"
echo "============================================================"
