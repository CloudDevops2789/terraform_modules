#!/usr/bin/env bash
set -uo pipefail

################################################################################
# Run every normal IRE Terraform plan through the real Ansible deploy playbook.
#
# This script never enables terraform_apply_enabled and never invokes the
# destroy playbook. It captures full stack logs and produces one review archive.
################################################################################

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/internal/run-ire-plan-matrix.sh COMMON_VARS_FILE [STACK_VARS_DIR]

COMMON_VARS_FILE:
  Untracked AAP-equivalent YAML containing AssumeRole, backend, environment,
  and Persistent contract-source variables.

STACK_VARS_DIR (optional):
  Directory containing optional persistent.yml, platform.yml, identity.yml,
  and recovery.yml files. Each may override terraform_variables for that stack.

Example:
  bash scripts/internal/run-ire-plan-matrix.sh \
    /home/svc_unix/.config/ire/aap-sandbox-vars.yml
USAGE
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage >&2
  exit 2
fi

common_vars_file="$1"
stack_vars_dir="${2:-}"

test -f "$common_vars_file" || {
  printf 'ERROR: common vars file not found: %s\n' "$common_vars_file" >&2
  exit 2
}

if [ -n "$stack_vars_dir" ] && [ ! -d "$stack_vars_dir" ]; then
  printf 'ERROR: stack vars directory not found: %s\n' "$stack_vars_dir" >&2
  exit 2
fi

repo_root="$(git rev-parse --show-toplevel)" || exit 2
cd "$repo_root" || exit 2

test -f "$repo_root/playbooks/terraform_deploy.yml" || {
  printf 'ERROR: run this script from the terraform_modules repository.\n' >&2
  exit 2
}

test -f "$repo_root/.venv-ansible-lint/bin/activate" || {
  printf 'ERROR: Ansible virtual environment is missing.\n' >&2
  exit 2
}

# shellcheck disable=SC1091
source "$repo_root/.venv-ansible-lint/bin/activate"

command -v ansible-playbook >/dev/null 2>&1 || {
  printf 'ERROR: ansible-playbook is unavailable.\n' >&2
  exit 2
}

command -v tar >/dev/null 2>&1 || {
  printf 'ERROR: tar is unavailable.\n' >&2
  exit 2
}

export ANSIBLE_CONFIG="$repo_root/ansible.cfg"
export ANSIBLE_COLLECTIONS_PATH="$repo_root/collections:/home/svc_unix/.ansible/collections"
export ANSIBLE_NOCOLOR=1
export ANSIBLE_FORCE_COLOR=0

plan_contract_source="${IRE_PLAN_CONTRACT_SOURCE:-managed}"

case "$plan_contract_source" in
  managed)
    plan_stacks=(persistent platform identity recovery)
    ;;
  external)
    # External resources are not managed by the Persistent stack.
    plan_stacks=(platform identity recovery)
    ;;
  *)
    printf 'ERROR: IRE_PLAN_CONTRACT_SOURCE must be managed or external.\n' >&2
    exit 2
    ;;
esac

output_root="${IRE_PLAN_OUTPUT_ROOT:-/mnt/c/Users/Yoganand/Downloads}"
test -d "$output_root" || {
  printf 'ERROR: output root does not exist: %s\n' "$output_root" >&2
  exit 2
}

run_timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
output_dir="$output_root/ire-local-plan-review-$run_timestamp"
archive_path="$output_dir.tar.gz"
control_dir="$output_dir/control"
logs_dir="$output_dir/logs"

mkdir -p "$control_dir" "$logs_dir"

summary_file="$output_dir/summary.tsv"
evidence_file="$output_dir/review-evidence.txt"

printf 'stack\texit_code\tresult\tlog\n' > "$summary_file"

{
  printf 'Generated UTC: %s\n' "$run_timestamp"
  printf 'Repository: %s\n' "$repo_root"
  printf 'Commit: %s\n' "$(git rev-parse HEAD)"
  printf 'Branch: %s\n' "$(git branch --show-current)"
  printf 'Contract source: %s\n' "$plan_contract_source"
  printf 'Common vars file: %s\n' "$common_vars_file"
  printf 'Stack vars directory: %s\n' "${stack_vars_dir:-none}"
} > "$output_dir/run-metadata.txt"

printf '%s\n' \
  '============================================================' \
  'IRE LOCAL ANSIBLE PLAN MATRIX' \
  '============================================================'

printf 'Contract source: %s\n' "$plan_contract_source"
printf 'Output directory: %s\n' "$output_dir"

overall_rc=0

for stack_name in "${plan_stacks[@]}"; do
  printf '\n%s\n' '------------------------------------------------------------'
  printf 'PLAN STACK: %s\n' "$stack_name"
  printf '%s\n' '------------------------------------------------------------'

  control_file="$control_dir/$stack_name-control.yml"
  log_file="$logs_dir/$stack_name-plan.log"
  stack_vars_file=""

  cat > "$control_file" <<CONTROL
---
terraform_stack: "$stack_name"
terraform_apply_enabled: false
terraform_persistent_contract_source: "$plan_contract_source"
terraform_variables: {}
CONTROL

  ansible_arguments=(
    ansible-playbook
    playbooks/terraform_deploy.yml
    --extra-vars "@$common_vars_file"
    --extra-vars "@$control_file"
  )

  if [ -n "$stack_vars_dir" ] && [ -f "$stack_vars_dir/$stack_name.yml" ]; then
    stack_vars_file="$stack_vars_dir/$stack_name.yml"
    ansible_arguments+=(--extra-vars "@$stack_vars_file")
  fi

  set +e
  "${ansible_arguments[@]}" 2>&1 | tee "$log_file"
  stack_rc="${PIPESTATUS[0]}"
  set -e

  if [ "$stack_rc" -eq 0 ]; then
    stack_result="successful"
  else
    stack_result="failed"
    overall_rc=1
  fi

  printf '%s\t%s\t%s\t%s\n' \
    "$stack_name" \
    "$stack_rc" \
    "$stack_result" \
    "logs/$stack_name-plan.log" \
    >> "$summary_file"

  {
    printf '============================================================\n'
    printf 'STACK: %s\n' "$stack_name"
    printf 'EXIT CODE: %s\n' "$stack_rc"
    printf 'RESULT: %s\n' "$stack_result"
    printf '============================================================\n'
    grep -E \
      'Backend key:|Persistent contract source:|Plan: [0-9]+ to add|No changes\.|plan completed successfully|FAILED!|fatal:|Error:' \
      "$log_file" || true
    printf '\n'
  } >> "$evidence_file"
done

tar \
  -czf "$archive_path" \
  -C "$(dirname "$output_dir")" \
  "$(basename "$output_dir")"

printf '\n%s\n' \
  '============================================================' \
  'PLAN MATRIX RESULT' \
  '============================================================'

if command -v column >/dev/null 2>&1; then
  column -t -s $'\t' "$summary_file"
else
  cat "$summary_file"
fi

printf '\nReview directory: %s\n' "$output_dir"
printf 'Review archive:   %s\n' "$archive_path"

if [ "$overall_rc" -ne 0 ]; then
  printf '\nOne or more plans failed. Upload the archive for review.\n' >&2
  exit "$overall_rc"
fi

printf '\nAll requested plans succeeded. Upload the archive for review.\n'
