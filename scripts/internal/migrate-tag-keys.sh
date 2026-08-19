#!/usr/bin/env bash

set -euo pipefail

MODE="dry-run"
ROOT="."
FROM_PREFIX=""
TO_PREFIX=""

#dry run example:
#bash /path/to/migrate-tag-keys.sh \
#  --root . \
#  --from-prefix org_ \
#  --to-prefix 'new_org:'
#Apply example:
#bash /path/to/migrate-tag-keys.sh \
#  --root . \
#  --from-prefix org_ \
#  --to-prefix 'company:' \
#  --apply

TAG_SUFFIXES=(
  "it_cost_center"
  "department"
  "cmdb_calculated_app"
  "business_criticality"
  "environment"
  "data_classification"
  "project_name"
  "managed_by"
)

usage() {
  cat <<'USAGE'
Usage:

  bash scripts/internal/migrate-tag-keys.sh \
    --from-prefix <prefix> \
    --to-prefix <prefix> \
    [--root <repository-path>] \
    [--apply]

Examples:

  Dry run:

    bash scripts/internal/migrate-tag-keys.sh \
      --from-prefix org_ \
      --to-prefix 'example:'

  Apply:

    bash scripts/internal/migrate-tag-keys.sh \
      --from-prefix org_ \
      --to-prefix 'example:' \
      --apply

The script changes AWS-facing standardized tag keys while preserving
Terraform variable and local identifiers.

Dry-run is the default.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from-prefix)
      FROM_PREFIX="${2:-}"
      shift 2
      ;;
    --to-prefix)
      TO_PREFIX="${2:-}"
      shift 2
      ;;
    --root)
      ROOT="${2:-}"
      shift 2
      ;;
    --apply)
      MODE="apply"
      shift
      ;;
    --dry-run)
      MODE="dry-run"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$FROM_PREFIX" || -z "$TO_PREFIX" ]]; then
  echo "ERROR: --from-prefix and --to-prefix are required." >&2
  usage
  exit 1
fi

if [[ ! "$FROM_PREFIX" =~ ^[A-Za-z0-9_:-]+$ ]]; then
  echo "ERROR: Unsupported characters in --from-prefix." >&2
  exit 1
fi

if [[ ! "$TO_PREFIX" =~ ^[A-Za-z0-9_:-]+$ ]]; then
  echo "ERROR: Unsupported characters in --to-prefix." >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git is required." >&2
  exit 1
fi

if ! command -v sed >/dev/null 2>&1; then
  echo "ERROR: sed is required." >&2
  exit 1
fi

if ! command -v grep >/dev/null 2>&1; then
  echo "ERROR: grep is required." >&2
  exit 1
fi

ROOT="$(cd "$ROOT" && pwd)"
cd "$ROOT"

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "ERROR: --root must point to a Git repository." >&2
  exit 1
fi

if [[ "$MODE" == "apply" ]] && [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: Working tree is not clean."
  echo "Commit or stash existing changes before running --apply."
  exit 1
fi

SOURCE_KEYS=()
TARGET_KEYS=()

for suffix in "${TAG_SUFFIXES[@]}"; do
  SOURCE_KEYS+=("${FROM_PREFIX}${suffix}")
  TARGET_KEYS+=("${TO_PREFIX}${suffix}")
done

echo "============================================================"
echo "AWS tag-key migration helper"
echo "============================================================"
echo "Repository : $ROOT"
echo "Mode       : $MODE"
echo "From       : $FROM_PREFIX"
echo "To         : $TO_PREFIX"
echo

echo "Tag mappings:"
for i in "${!SOURCE_KEYS[@]}"; do
  printf '  %-35s -> %s\n' "${SOURCE_KEYS[$i]}" "${TARGET_KEYS[$i]}"
done

echo
echo "============================================================"
echo "Candidate HCL tag-key assignments"
echo "============================================================"

candidate_count=0

while IFS= read -r -d '' file; do
  [[ "$file" == *.terraform.lock.hcl ]] && continue

  for source_key in "${SOURCE_KEYS[@]}"; do
    matches="$(
      grep -nE \
        "^[[:space:]]*\"?${source_key}\"?[[:space:]]*=" \
        "$file" \
        2>/dev/null || true
    )"

    if [[ -n "$matches" ]]; then
      echo
      echo "--- $file"
      echo "$matches"
      candidate_count=$((candidate_count + 1))
    fi
  done
done < <(git ls-files -z -- '*.tf' '*.hcl')

echo
echo "============================================================"
echo "AWS IAM tag-condition references"
echo "============================================================"

for source_key in "${SOURCE_KEYS[@]}"; do
  git grep -n -E \
    "aws:(RequestTag|ResourceTag|PrincipalTag)/${source_key}" \
    -- '*.tf' '*.hcl' '*.json' '*.yaml' '*.yml' \
    2>/dev/null || true
done

if [[ "$MODE" == "dry-run" ]]; then
  echo
  echo "============================================================"
  echo "DRY RUN COMPLETE"
  echo "============================================================"
  echo
  echo "No files were changed."
  echo
  echo "Review the candidates above."
  echo
  echo "When satisfied, rerun with:"
  echo
  echo "  --apply"
  exit 0
fi

echo
echo "============================================================"
echo "Applying tag-key migration"
echo "============================================================"

while IFS= read -r -d '' file; do
  [[ "$file" == *.terraform.lock.hcl ]] && continue

  sed_args=()

  for i in "${!SOURCE_KEYS[@]}"; do
    source_key="${SOURCE_KEYS[$i]}"
    target_key="${TARGET_KEYS[$i]}"

    sed_args+=(
      -e "s|^([[:space:]]*)${source_key}([[:space:]]*=)|\\1\"${target_key}\"\\2|"
      -e "s|^([[:space:]]*)\"${source_key}\"([[:space:]]*=)|\\1\"${target_key}\"\\2|"
    )
  done

  tmp_file="${file}.tag-migration.$$"

  sed -E "${sed_args[@]}" "$file" > "$tmp_file"

  if cmp -s "$file" "$tmp_file"; then
    rm -f "$tmp_file"
  else
    mv "$tmp_file" "$file"
  fi

done < <(git ls-files -z -- '*.tf' '*.hcl')

while IFS= read -r -d '' file; do
  [[ "$file" == *.terraform.lock.hcl ]] && continue

  sed_args=()

  for i in "${!SOURCE_KEYS[@]}"; do
    source_key="${SOURCE_KEYS[$i]}"
    target_key="${TARGET_KEYS[$i]}"

    sed_args+=(
      -e "s|(aws:(RequestTag|ResourceTag|PrincipalTag)/)${source_key}|\\1${target_key}|g"
    )
  done

  tmp_file="${file}.tag-migration.$$"

  sed -E "${sed_args[@]}" "$file" > "$tmp_file"

  if cmp -s "$file" "$tmp_file"; then
    rm -f "$tmp_file"
  else
    mv "$tmp_file" "$file"
  fi

done < <(
  git ls-files -z -- \
    '*.tf' \
    '*.hcl' \
    '*.json' \
    '*.yaml' \
    '*.yml'
)

echo
echo "============================================================"
echo "Migration complete"
echo "============================================================"

echo
echo "Changed files:"
git status --short

echo
echo "Diff summary:"
git diff --stat

echo
echo "Whitespace check:"
git diff --check

echo
echo "============================================================"
echo "Remaining source-key references requiring review"
echo "============================================================"
echo
echo "These are NOT automatically modified because they may be"
echo "Terraform variable names or other non-tag identifiers."
echo

for source_key in "${SOURCE_KEYS[@]}"; do
  git grep -n -F "$source_key" \
    -- '*.tf' '*.tfvars' '*.tfvars.example' '*.hcl' '*.json' '*.yaml' '*.yml' \
    2>/dev/null || true
done
