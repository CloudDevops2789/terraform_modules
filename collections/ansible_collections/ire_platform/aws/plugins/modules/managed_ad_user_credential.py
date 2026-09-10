#!/usr/bin/python
"""Provision one Managed AD user credential through AWS APIs."""

from __future__ import annotations

import json

DOCUMENTATION = r"""
---
module: managed_ad_user_credential
short_description: Provision a unique AWS Managed Microsoft AD user credential
description:
  - Generates a unique random password using AWS Secrets Manager.
  - Sets or resets the password for one AWS Managed Microsoft AD user.
  - Stores the resulting credential in one AWS Secrets Manager secret.
  - Never returns the generated plaintext password.
options:
  directory_id:
    description: AWS Managed Microsoft AD directory ID.
    required: true
    type: str
  user_name:
    description: SAM account name of the directory user.
    required: true
    type: str
  secret_name:
    description: AWS Secrets Manager secret name for this user.
    required: true
    type: str
  region:
    description: AWS Region containing the directory and secret.
    required: true
    type: str
  password_length:
    description: Length of the generated random password.
    type: int
    default: 24
author:
  - IRE Platform Engineering
requirements:
  - boto3
  - botocore
"""

EXAMPLES = r"""
- name: Provision one Managed AD user credential
  ire_platform.aws.managed_ad_user_credential:
    directory_id: d-0123456789
    user_name: yog73018
    secret_name: ire/sandbox/ad-users/yog73018
    region: us-east-1
"""

RETURN = r"""
user_name:
  description: Directory user whose credential was provisioned.
  returned: always
  type: str
secret_name:
  description: Secrets Manager name containing the credential.
  returned: always
  type: str
secret_created:
  description: Whether this execution created the secret.
  returned: always
  type: bool
password_changed:
  description: Whether the Managed AD password was changed.
  returned: always
  type: bool
"""

try:
    import boto3
    from botocore.exceptions import BotoCoreError, ClientError

    BOTO3_AVAILABLE = True
except ImportError:
    BOTO3_AVAILABLE = False

from ansible.module_utils.basic import AnsibleModule


def _error_code(error: ClientError) -> str:
    """Return the AWS service error code."""
    return error.response.get("Error", {}).get("Code", "Unknown")


def run_module() -> None:
    """Execute the credential lifecycle."""
    module = AnsibleModule(
        argument_spec={
            "directory_id": {"type": "str", "required": True},
            "user_name": {"type": "str", "required": True},
            "secret_name": {"type": "str", "required": True},
            "region": {"type": "str", "required": True},
            "password_length": {"type": "int", "default": 24},
        },
        supports_check_mode=False,
    )

    if not BOTO3_AVAILABLE:
        module.fail_json(
            msg="boto3 and botocore are required in the execution environment."
        )

    params = module.params

    if params["password_length"] < 16:
        module.fail_json(
            msg="password_length must be at least 16 characters."
        )

    result = {
        "changed": False,
        "user_name": params["user_name"],
        "secret_name": params["secret_name"],
        "secret_created": False,
        "password_changed": False,
    }

    try:
        session = boto3.session.Session(region_name=params["region"])
        directory_client = session.client("ds")
        secrets_client = session.client("secretsmanager")

        ########################################################################
        # Generate the password inside the AWS SDK path.
        #
        # RequireEachIncludedType ensures the generated value contains at least
        # one character from every included character class.
        ########################################################################

        random_password_response = secrets_client.get_random_password(
            PasswordLength=params["password_length"],
            ExcludeUppercase=False,
            ExcludeLowercase=False,
            ExcludeNumbers=False,
            ExcludePunctuation=False,
            IncludeSpace=False,
            RequireEachIncludedType=True,
        )

        password = random_password_response["RandomPassword"]

        ########################################################################
        # Build the secret entirely in process memory.
        ########################################################################

        secret_value = json.dumps(
            {
                "username": params["user_name"],
                "password": password,
                "directory_id": params["directory_id"],
            }
        )

        ########################################################################
        # Persist the generated credential before changing Managed AD.
        #
        # This ordering prevents a successful AD password reset from leaving
        # the administrator with an unrecoverable password when Secrets Manager
        # is unavailable or the caller lacks permission to store the secret.
        #
        # If the secret already exists, write a new version. Normal idempotent
        # runs never invoke this module for existing users unless password reset
        # was explicitly requested.
        ########################################################################

        try:
            secrets_client.create_secret(
                Name=params["secret_name"],
                Description=(
                    "Bootstrap credential for AWS Managed Microsoft AD user "
                    f"{params['user_name']}"
                ),
                SecretString=secret_value,
            )
            result["secret_created"] = True

        except ClientError as error:
            if _error_code(error) != "ResourceExistsException":
                raise

            secrets_client.put_secret_value(
                SecretId=params["secret_name"],
                SecretString=secret_value,
            )

        ########################################################################
        # Set/reset the directory password only after the credential is safely
        # persisted in Secrets Manager.
        #
        # The plaintext credential never becomes a shell/process argument.
        ########################################################################

        directory_client.reset_user_password(
            DirectoryId=params["directory_id"],
            UserName=params["user_name"],
            NewPassword=password,
        )
        result["password_changed"] = True

        ########################################################################
        # Do not include the generated password in the Ansible result.
        ########################################################################

        result["changed"] = True
        module.exit_json(**result)

    except (BotoCoreError, ClientError, KeyError, ValueError) as error:
        module.fail_json(msg=str(error), **result)


def main() -> None:
    """Module entry point."""
    run_module()


if __name__ == "__main__":
    main()
