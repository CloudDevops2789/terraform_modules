#!/usr/bin/python
"""Schedule one Managed AD bootstrap secret for deletion."""

from __future__ import annotations

DOCUMENTATION = r"""
---
module: managed_ad_user_secret_cleanup
short_description: Schedule one Managed AD bootstrap secret for deletion
description:
  - Schedules one AWS Secrets Manager secret for deletion.
  - Uses a configurable recovery window from 7 through 30 days.
  - Treats absent or already scheduled secrets as idempotent outcomes.
  - Does not support immediate force deletion.
options:
  secret_name:
    description: AWS Secrets Manager secret name.
    required: true
    type: str
  region:
    description: AWS Region containing the secret.
    required: true
    type: str
  recovery_window_days:
    description: Secrets Manager recovery window in days.
    required: true
    type: int
author:
  - IRE Platform Engineering
requirements:
  - boto3
  - botocore
"""

EXAMPLES = r"""
- name: Schedule one bootstrap credential secret for deletion
  ire_platform.aws.managed_ad_user_secret_cleanup:
    secret_name: ire/sandbox/ad-users/user01
    region: us-east-1
    recovery_window_days: 7
"""

RETURN = r"""
secret_name:
  description: Requested secret name.
  returned: always
  type: str
secrets_scheduled:
  description: Secrets newly scheduled for deletion.
  returned: always
  type: list
secrets_already_scheduled:
  description: Secrets that were already scheduled for deletion.
  returned: always
  type: list
secrets_missing:
  description: Secrets that were already absent.
  returned: always
  type: list
"""

try:
    import boto3
    from botocore.exceptions import BotoCoreError, ClientError

    BOTO3_AVAILABLE = True
except ImportError:
    BOTO3_AVAILABLE = False

from ansible.module_utils.basic import AnsibleModule


def _error_code(error: ClientError) -> str:
    return error.response.get("Error", {}).get("Code", "Unknown")


def run_module() -> None:
    module = AnsibleModule(
        argument_spec={
            "secret_name": {"type": "str", "required": True},
            "region": {"type": "str", "required": True},
            "recovery_window_days": {"type": "int", "required": True},
        },
        supports_check_mode=False,
    )

    if not BOTO3_AVAILABLE:
        module.fail_json(
            msg="boto3 and botocore are required in the execution environment."
        )

    params = module.params

    secret_name = params["secret_name"].strip()
    recovery_window_days = params["recovery_window_days"]

    if not secret_name:
        module.fail_json(msg="secret_name must not be empty.")

    if recovery_window_days < 7 or recovery_window_days > 30:
        module.fail_json(
            msg="recovery_window_days must be between 7 and 30."
        )

    result = {
        "changed": False,
        "secret_name": secret_name,
        "secrets_scheduled": [],
        "secrets_already_scheduled": [],
        "secrets_missing": [],
    }

    try:
        session = boto3.session.Session(region_name=params["region"])
        secrets_client = session.client("secretsmanager")

        try:
            secret = secrets_client.describe_secret(
                SecretId=secret_name,
            )
        except ClientError as error:
            if _error_code(error) == "ResourceNotFoundException":
                result["secrets_missing"].append(secret_name)
                module.exit_json(**result)
            raise

        if secret.get("DeletedDate"):
            result["secrets_already_scheduled"].append(secret_name)
            module.exit_json(**result)

        secrets_client.delete_secret(
            SecretId=secret_name,
            RecoveryWindowInDays=recovery_window_days,
        )

        result["changed"] = True
        result["secrets_scheduled"].append(secret_name)

        module.exit_json(**result)

    except (BotoCoreError, ClientError, ValueError) as error:
        module.fail_json(msg=str(error), **result)


def main() -> None:
    run_module()


if __name__ == "__main__":
    main()
