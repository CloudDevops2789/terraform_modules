#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

VALIDATOR="scripts/ci/terraform-validate-root.sh"
TEST_ROOT="terraform/environments/module-tests"

if [ ! -x "$VALIDATOR" ]; then
  echo "ERROR: Terraform validation helper is missing or not executable: $VALIDATOR"
  exit 1
fi

mapfile -t ROOTS < <(
  for dir in "$TEST_ROOT"/*; do
    [ -d "$dir" ] || continue

    if find "$dir" -maxdepth 1 -name '*.tf' -print -quit | grep -q .; then
      echo "$dir"
    fi
  done | sort
)

if [ "${#ROOTS[@]}" -eq 0 ]; then
  echo "ERROR: No Terraform module-test roots were discovered."
  exit 1
fi

echo "============================================================"
echo "Full Terraform module-test validation"
echo "Discovered roots: ${#ROOTS[@]}"
echo "============================================================"

for root in "${ROOTS[@]}"; do
  echo
  "$VALIDATOR" "$root"
done

echo
echo "============================================================"
echo "ALL MODULE TEST VALIDATIONS PASSED"
echo "Validated roots: ${#ROOTS[@]}"
echo "============================================================"
