#!/usr/bin/env python3

from __future__ import annotations

import argparse
import difflib
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path


MODULE_TESTS_DIR = Path("module-tests")

DEFAULT_TAGS_EXPRESSION = """merge(
    {
      org_it_cost_center       = var.org_it_cost_center
      org_department           = var.org_department
      org_cmdb_calculated_app  = var.org_cmdb_calculated_app
      org_business_criticality = var.org_business_criticality
      org_environment          = var.org_environment
      org_data_classification  = var.org_data_classification

      Project   = var.project_name
      ManagedBy = "Terraform"
    },
    var.additional_tags
  )"""

REQUIRED_VARIABLES = {
    "org_it_cost_center": """variable "org_it_cost_center" {
  description = "Organization IT cost center."
  type        = string
}""",
    "org_department": """variable "org_department" {
  description = "Organization department."
  type        = string
}""",
    "org_cmdb_calculated_app": """variable "org_cmdb_calculated_app" {
  description = "CMDB calculated application identifier."
  type        = string
}""",
    "org_business_criticality": """variable "org_business_criticality" {
  description = "Business criticality classification."
  type        = string

  validation {
    condition     = contains(["1", "2", "3", "4"], var.org_business_criticality)
    error_message = "org_business_criticality must be 1, 2, 3, or 4."
  }
}""",
    "org_environment": """variable "org_environment" {
  description = "Enterprise environment classification."
  type        = string

  validation {
    condition = contains(
      ["sandbox", "dev", "test", "qa", "stage", "prod"],
      lower(var.org_environment)
    )
    error_message = "org_environment must be sandbox, dev, test, qa, stage, or prod."
  }
}""",
    "org_data_classification": """variable "org_data_classification" {
  description = "Enterprise data classification."
  type        = string

  validation {
    condition = contains(
      ["public", "internal", "confidential", "restricted"],
      lower(var.org_data_classification)
    )
    error_message = "org_data_classification must be public, internal, confidential, or restricted."
  }
}""",
    "project_name": """variable "project_name" {
  description = "Project name."
  type        = string
}""",
    "additional_tags": """variable "additional_tags" {
  description = "Additional tags applied to resources in this test root."
  type        = map(string)
  default     = {}
}""",
}

TFVARS_CONTENT = """# Enterprise tags used by this module test root.
org_it_cost_center       = "999999999"
org_department           = "cloud"
org_cmdb_calculated_app  = "cloud_app"
org_business_criticality = "4"
org_environment          = "dev"
org_data_classification  = "internal"

project_name = "AWS-IRE"

additional_tags = {
  TestType = "ModuleTest"
}
"""


def matching_delimiter(text: str, start: int, opener: str, closer: str) -> int:
    """Return the index of the matching closing delimiter."""
    depth = 0
    in_string = False
    escaped = False
    i = start

    while i < len(text):
        char = text[i]

        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
        else:
            if char == '"':
                in_string = True
            elif char == opener:
                depth += 1
            elif char == closer:
                depth -= 1
                if depth == 0:
                    return i

        i += 1

    raise ValueError(
        f"Could not find matching {closer!r} for delimiter at offset {start}"
    )


def replace_provider_default_tags(text: str) -> tuple[str, bool]:
    """
    Replace provider-level:

      default_tags {
        tags = { ... }
      }

    with:

      default_tags {
        tags = local.default_tags
      }
    """
    match = re.search(r"\bdefault_tags\s*\{", text)

    if not match:
        return text, False

    opening_brace = text.find("{", match.start())
    closing_brace = matching_delimiter(text, opening_brace, "{", "}")

    current_block = text[match.start():closing_brace + 1]

    if re.search(r"tags\s*=\s*local\.default_tags", current_block):
        return text, False

    indent_match = re.search(r"(?m)^([ \t]*)default_tags\s*\{", current_block)
    indent = indent_match.group(1) if indent_match else "  "

    replacement = (
        f"{indent}default_tags {{\n"
        f"{indent}  tags = local.default_tags\n"
        f"{indent}}}"
    )

    updated = text[:match.start()] + replacement + text[closing_brace + 1:]
    return updated, True


def replace_local_default_tags(text: str) -> tuple[str, bool]:
    """
    Replace only the local.default_tags assignment.

    Other locals in the same locals.tf file are preserved.
    """
    assignment = re.search(r"(?m)^([ \t]*)default_tags\s*=\s*", text)

    if not assignment:
        # Add a locals block if none exists.
        addition = (
            "\n\nlocals {\n"
            f"  default_tags = {DEFAULT_TAGS_EXPRESSION}\n"
            "}\n"
        )
        return text.rstrip() + addition, True

    indent = assignment.group(1)
    value_start = assignment.end()

    while value_start < len(text) and text[value_start].isspace():
        value_start += 1

    if text.startswith("merge(", value_start):
        open_paren = text.find("(", value_start)
        value_end = matching_delimiter(text, open_paren, "(", ")") + 1
    elif value_start < len(text) and text[value_start] == "{":
        value_end = matching_delimiter(text, value_start, "{", "}") + 1
    else:
        line_end = text.find("\n", value_start)
        value_end = len(text) if line_end == -1 else line_end

    current_value = text[value_start:value_end]

    if "org_it_cost_center" in current_value and "var.additional_tags" in current_value:
        return text, False

    formatted_expression = DEFAULT_TAGS_EXPRESSION.replace(
        "\n", "\n" + indent
    )

    replacement = f"{indent}default_tags = {formatted_expression}"

    updated = text[:assignment.start()] + replacement + text[value_end:]
    return updated, True


def add_required_variables(text: str) -> tuple[str, list[str]]:
    added: list[str] = []
    blocks: list[str] = []

    for variable_name, block in REQUIRED_VARIABLES.items():
        pattern = rf'variable\s+"{re.escape(variable_name)}"\s*\{{'

        if not re.search(pattern, text):
            blocks.append(block)
            added.append(variable_name)

    if not blocks:
        return text, added

    updated = text.rstrip() + "\n\n" + "\n\n".join(blocks) + "\n"
    return updated, added


def show_diff(path: Path, old: str, new: str) -> None:
    diff = difflib.unified_diff(
        old.splitlines(),
        new.splitlines(),
        fromfile=str(path),
        tofile=str(path),
        lineterm="",
    )

    print("\n".join(diff))


def write_change(
    path: Path,
    old: str,
    new: str,
    backup_root: Path,
    dry_run: bool,
) -> bool:
    if old == new:
        return False

    if dry_run:
        show_diff(path, old, new)
        return True

    backup_path = backup_root / path
    backup_path.parent.mkdir(parents=True, exist_ok=True)

    if path.exists():
        shutil.copy2(path, backup_path)

    path.write_text(new, encoding="utf-8")
    print(f"UPDATED  {path}")
    return True


def run_terraform_fmt() -> None:
    terraform = shutil.which("terraform")

    if not terraform:
        print("\nWARNING: terraform command not found; skipping formatting.")
        return

    print("\nRunning terraform fmt -recursive module-tests ...")

    result = subprocess.run(
        [terraform, "fmt", "-recursive", str(MODULE_TESTS_DIR)],
        text=True,
        capture_output=True,
        check=False,
    )

    if result.stdout.strip():
        print(result.stdout.strip())

    if result.returncode != 0:
        print(result.stderr.strip(), file=sys.stderr)
        raise RuntimeError("terraform fmt failed")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Migrate module-test roots to enterprise provider default tags."
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Write changes. Without this option, the script performs a dry run.",
    )
    parser.add_argument(
        "--overwrite-tfvars",
        action="store_true",
        help="Overwrite existing enterprise-tags.auto.tfvars files.",
    )
    args = parser.parse_args()

    dry_run = not args.apply

    if not MODULE_TESTS_DIR.is_dir():
        print(
            f"ERROR: {MODULE_TESTS_DIR} was not found.\n"
            "Run this script from terraform/environments.",
            file=sys.stderr,
        )
        return 1

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_root = Path(f".tag-migration-backup-{timestamp}")

    test_roots = sorted(
        directory
        for directory in MODULE_TESTS_DIR.iterdir()
        if directory.is_dir()
    )

    changed_files = 0
    test_roots_updated = 0

    print(f"Mode: {'DRY RUN' if dry_run else 'APPLY'}")
    print(f"Discovered {len(test_roots)} module-test directories.")

    for test_root in test_roots:
        provider_file = test_root / "provider.tf"
        locals_file = test_root / "locals.tf"
        variables_file = test_root / "variables.tf"
        tfvars_file = test_root / "enterprise-tags.auto.tfvars"

        root_changed = False

        if provider_file.exists():
            old = provider_file.read_text(encoding="utf-8")
            new, changed = replace_provider_default_tags(old)

            if changed:
                root_changed |= write_change(
                    provider_file,
                    old,
                    new,
                    backup_root,
                    dry_run,
                )
                changed_files += 1
        else:
            print(f"SKIPPED  {test_root}: provider.tf not found")

        old = (
            locals_file.read_text(encoding="utf-8")
            if locals_file.exists()
            else ""
        )
        new, changed = replace_local_default_tags(old)

        if changed:
            root_changed |= write_change(
                locals_file,
                old,
                new,
                backup_root,
                dry_run,
            )
            changed_files += 1

        old = (
            variables_file.read_text(encoding="utf-8")
            if variables_file.exists()
            else ""
        )
        new, added_variables = add_required_variables(old)

        if added_variables:
            root_changed |= write_change(
                variables_file,
                old,
                new,
                backup_root,
                dry_run,
            )
            changed_files += 1
            print(
                f"VARIABLES {test_root}: "
                + ", ".join(added_variables)
            )

        if not tfvars_file.exists() or args.overwrite_tfvars:
            old = (
                tfvars_file.read_text(encoding="utf-8")
                if tfvars_file.exists()
                else ""
            )

            root_changed |= write_change(
                tfvars_file,
                old,
                TFVARS_CONTENT,
                backup_root,
                dry_run,
            )
            changed_files += 1
        else:
            print(f"KEPT     {tfvars_file}")

        if root_changed:
            test_roots_updated += 1

    if dry_run:
        print(
            "\nDry run complete. No files were changed.\n"
            "Review the diff, then run:\n\n"
            "  python3 migrate_module_test_tags.py --apply\n"
        )
    else:
        run_terraform_fmt()

        print(f"\nBackup directory: {backup_root}")
        print(f"Updated roots:    {test_roots_updated}")
        print(f"Changed files:    {changed_files}")

        print(
            "\nPost-migration checks:\n"
            "  rg -n 'Environment|Owner|ManagedBy|Project' "
            "module-tests --glob '*.tf'\n\n"
            "  rg -n 'default_tags|org_it_cost_center' "
            "module-tests --glob '*.tf'\n"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
