#!/usr/bin/env bash

################################################################################
#
# Terraform Module Test Validator
#
# Validates every module test by running:
#
#   • terraform fmt
#   • terraform init
#   • terraform validate
#   • terraform plan
#
# Usage:
#
#   ./validate.sh
#
################################################################################

set -uo pipefail

################################################################################
# Colours
################################################################################

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

################################################################################
# Root Directory
################################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TOTAL=0
PASSED=0
FAILED=()

echo
echo "======================================================================="
echo "              Terraform Module Test Validation"
echo "======================================================================="

for dir in "$ROOT_DIR"/*; do

    [[ -d "$dir" ]] || continue

    MODULE="$(basename "$dir")"

    # Skip folders without Terraform files
    if ! compgen -G "$dir/*.tf" >/dev/null; then
        continue
    fi

    TOTAL=$((TOTAL + 1))

    echo
    echo "-----------------------------------------------------------------------"
    echo -e "${BLUE}Validating:${NC} ${MODULE}"
    echo "-----------------------------------------------------------------------"

    ###########################################################################
    # Cleanup previous run
    ###########################################################################

    rm -rf "$dir/.terraform"
    rm -f "$dir/.terraform.lock.hcl"
    rm -f "$dir/tfplan"

    ###########################################################################
    # terraform fmt
    ###########################################################################

    echo -e "${YELLOW}[1/4] terraform fmt${NC}"

    if ! terraform -chdir="$dir" fmt -recursive; then
        echo -e "${RED}✗ terraform fmt failed${NC}"
        FAILED+=("$MODULE (fmt)")
        continue
    fi

    ###########################################################################
    # terraform init
    ###########################################################################

    echo -e "${YELLOW}[2/4] terraform init${NC}"

    if ! terraform -chdir="$dir" init \
        -reconfigure \
        -input=false; then

        echo -e "${RED}✗ terraform init failed${NC}"
        FAILED+=("$MODULE (init)")
        continue
    fi

    ###########################################################################
    # terraform validate
    ###########################################################################

    echo -e "${YELLOW}[3/4] terraform validate${NC}"

    if ! terraform -chdir="$dir" validate; then
        echo -e "${RED}✗ terraform validate failed${NC}"
        FAILED+=("$MODULE (validate)")
        continue
    fi

    ###########################################################################
    # terraform plan
    ###########################################################################

    echo -e "${YELLOW}[4/4] terraform plan${NC}"

    if ! terraform -chdir="$dir" plan \
        -input=false \
        -lock=false \
        -out=tfplan; then

        echo -e "${RED}✗ terraform plan failed${NC}"
        FAILED+=("$MODULE (plan)")
        rm -f "$dir/tfplan"
        continue
    fi

    ###########################################################################
    # Cleanup
    ###########################################################################

    rm -f "$dir/tfplan"

    PASSED=$((PASSED + 1))

    echo -e "${GREEN}✔ ${MODULE} passed${NC}"

done

################################################################################
# Summary
################################################################################

echo
echo "======================================================================="
echo "Validation Summary"
echo "======================================================================="

echo
echo "Modules Validated : $TOTAL"
echo "Modules Passed    : $PASSED"
echo "Modules Failed    : $((TOTAL - PASSED))"

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo
    echo -e "${RED}Failed Modules:${NC}"

    for module in "${FAILED[@]}"; do
        echo "  - $module"
    done

    exit 1
fi

echo
echo -e "${GREEN}All module tests validated successfully.${NC}"
echo