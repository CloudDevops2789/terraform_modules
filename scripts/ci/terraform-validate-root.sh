#!/usr/bin/env bash

set -euo pipefail

ROOT="${1:?Usage: terraform-validate-root.sh <terraform-root>}"

if [ ! -d "$ROOT" ]; then
  echo "ERROR: Terraform root does not exist: $ROOT"
  exit 1
fi

if ! find "$ROOT" -maxdepth 1 -name '*.tf' -print -quit | grep -q .; then
  echo "ERROR: No Terraform configuration found in: $ROOT"
  exit 1
fi

SAFE_NAME="$(printf '%s' "$ROOT" | tr '/ ' '__')"

TF_DATA_DIR="${TF_DATA_DIR:-/tmp/terraform-ci/${SAFE_NAME}}"
TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-/tmp/terraform-plugin-cache}"

mkdir -p "$TF_DATA_DIR"
mkdir -p "$TF_PLUGIN_CACHE_DIR"

export TF_DATA_DIR
export TF_PLUGIN_CACHE_DIR
export TF_IN_AUTOMATION=true

echo "============================================================"
echo "Terraform validation root: $ROOT"
echo "============================================================"

terraform \
  -chdir="$ROOT" \
  init \
  -backend=false \
  -input=false \
  -lockfile=readonly

terraform \
  -chdir="$ROOT" \
  validate

echo "PASS: $ROOT"
