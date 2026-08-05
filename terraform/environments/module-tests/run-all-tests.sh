#!/usr/bin/env bash
set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${ROOT_DIR}/test-logs/$(date +%Y%m%d-%H%M%S)"
FAILED_TESTS=()
PASSED_TESTS=()
mkdir -p "$LOG_DIR"
mapfile -t TEST_DIRS < <(
  find "$ROOT_DIR" -mindepth 1 -type f -name "*.tf" -printf '%h\n' |
  sort -u |
  while IFS= read -r dir; do
    if find "$dir" -maxdepth 1 -type f -name "*.tf" | grep -q .; then
      printf '%s\n' "$dir"
    fi
  done
)
run_test() {
  local dir="$1"
  local name
  local log
  local plan_exit
  local test_failed=0
  name="${dir#"$ROOT_DIR"/}"
  log="$LOG_DIR/${name//\//__}.log"
  echo "=================================================================================================="
  echo "TESTING: $name"
  echo "LOG: $log"
  echo "=================================================================================================="
  {
    echo "Test started: $(date -Is)"
    echo "Directory: $dir"
  } > "$log"
  cd "$dir" || return 1
  if ! terraform fmt -check -recursive >> "$log" 2>&1; then
    echo "FAILED: terraform fmt -check"
    test_failed=1
  fi
  if [ -f backend.hcl ]; then
    if ! terraform init -input=false -reconfigure -backend-config=backend.hcl >> "$log" 2>&1; then
      echo "FAILED: terraform init"
      test_failed=1
    fi
  else
    if ! terraform init -input=false -reconfigure >> "$log" 2>&1; then
      echo "FAILED: terraform init"
      test_failed=1
    fi
  fi
  if ! terraform validate >> "$log" 2>&1; then
    echo "FAILED: terraform validate"
    test_failed=1
  fi
  if [ "$test_failed" -eq 0 ]; then
    if ! terraform plan -input=false -out=tfplan >> "$log" 2>&1; then
      echo "FAILED: terraform plan"
      test_failed=1
    fi
  fi
  if [ "$test_failed" -eq 0 ]; then
    if ! terraform apply -input=false -auto-approve tfplan >> "$log" 2>&1; then
      echo "FAILED: terraform apply"
      test_failed=1
    fi
  fi
  if [ "$test_failed" -eq 0 ]; then
    terraform plan -input=false -detailed-exitcode >> "$log" 2>&1
    plan_exit=$?
    case "$plan_exit" in
      0)
        echo "PASSED: idempotency check"
        ;;
      1)
        echo "FAILED: idempotency plan returned an error"
        test_failed=1
        ;;
      2)
        echo "FAILED: post-apply plan detected changes"
        test_failed=1
        ;;
      *)
        echo "FAILED: unexpected plan exit code $plan_exit"
        test_failed=1
        ;;
    esac
  fi
  echo "Destroying test infrastructure..."
  if ! terraform destroy -input=false -auto-approve >> "$log" 2>&1; then
    echo "CRITICAL: terraform destroy failed for $name"
    echo "Inspect: $log"
    test_failed=1
  fi
  rm -f tfplan
  if [ "$test_failed" -eq 0 ]; then
    PASSED_TESTS+=("$name")
    echo "RESULT: PASSED — $name"
  else
    FAILED_TESTS+=("$name")
    echo "RESULT: FAILED — $name"
  fi
}
echo "Discovered ${#TEST_DIRS[@]} Terraform test roots."
for dir in "${TEST_DIRS[@]}"; do
  run_test "$dir"
done
echo
echo "=================================================================================================="
echo "TEST SUMMARY"
echo "=================================================================================================="
echo "Passed: ${#PASSED_TESTS[@]}"
printf '  PASS: %s\n' "${PASSED_TESTS[@]}"
echo "Failed: ${#FAILED_TESTS[@]}"
if [ "${#FAILED_TESTS[@]}" -gt 0 ]; then
  printf '  FAIL: %s\n' "${FAILED_TESTS[@]}"
  echo "Logs: $LOG_DIR"
  exit 1
fi
echo "All module tests passed."
echo "Logs: $LOG_DIR"