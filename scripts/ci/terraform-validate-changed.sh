#!/usr/bin/env bash

set -euo pipefail

BASE_REF="${1:?Usage: terraform-validate-changed.sh <base-ref> [head-ref]}"
HEAD_REF="${2:-HEAD}"

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

VALIDATOR="scripts/ci/terraform-validate-root.sh"

if [ ! -x "$VALIDATOR" ]; then
  echo "ERROR: Terraform validation helper is missing or not executable: $VALIDATOR"
  exit 1
fi

echo "============================================================"
echo "Changed Terraform module validation"
echo "Base: $BASE_REF"
echo "Head: $HEAD_REF"
echo "============================================================"

mapfile -t CHANGED_MODULES < <(
  git diff --name-only "$BASE_REF...$HEAD_REF" -- 'terraform/modules/**/*.tf' |
    awk -F/ 'NF >= 4 {print $3}' |
    sort -u
)

if [ "${#CHANGED_MODULES[@]}" -eq 0 ]; then
  echo "No reusable Terraform modules changed."
  exit 0
fi

echo
echo "Changed reusable modules:"
printf '  - %s\n' "${CHANGED_MODULES[@]}"

declare -A ROOTS=()
declare -A MODULE_HAS_CONSUMER=()

for module in "${CHANGED_MODULES[@]}"; do
  MODULE_HAS_CONSUMER["$module"]=false

  echo
  echo "Discovering validation consumers for module: $module"

  while IFS= read -r file; do
    [ -n "$file" ] || continue

    root="$(dirname "$file")"

    while [ "$root" != "." ] && [ "$root" != "/" ]; do
      if [[ "$root" == terraform/environments/module-tests/* ]] &&
         find "$root" -maxdepth 1 -name '*.tf' -print -quit | grep -q .; then
        ROOTS["$root"]=1
        MODULE_HAS_CONSUMER["$module"]=true
        echo "  module-test: $root"
        break
      fi
      root="$(dirname "$root")"
    done
  done < <(
  git grep -l -E \
    "source[[:space:]]*=[[:space:]]*\"../../../modules/${module}\"" \
    -- ':(glob)terraform/environments/module-tests/**/*.tf' \
    || true
)

  while IFS= read -r file; do
    [ -n "$file" ] || continue

    root="$(dirname "$file")"
    ROOTS["$root"]=1
    MODULE_HAS_CONSUMER["$module"]=true
    echo "  lifecycle stack: $root"
  done < <(
    git grep -l -E \
      "source[[:space:]]*=[[:space:]]*\"../../modules/${module}\"" \
      -- ':(glob)terraform/stacks/*/*.tf' \
      || true
  )

  if [ "${MODULE_HAS_CONSUMER[$module]}" = false ]; then
    echo "ERROR: Changed module '$module' has no discovered module-test or lifecycle-stack validation consumer."
    echo "Add a validation consumer before merging changes to this module."
    exit 1
  fi
done

echo
echo "Terraform roots selected for validation:"

mapfile -t SORTED_ROOTS < <(
  printf '%s\n' "${!ROOTS[@]}" | sort
)

printf '  - %s\n' "${SORTED_ROOTS[@]}"

echo

for root in "${SORTED_ROOTS[@]}"; do
  "$VALIDATOR" "$root"
done

echo
echo "============================================================"
echo "Changed-module validation passed"
echo "Validated roots: ${#SORTED_ROOTS[@]}"
echo "============================================================"
