#!/usr/bin/python
"""Provision one AWS Managed Microsoft AD user credential."""

from __future__ import annotations

import json

DOCUMENTATION = r"""
---
module: managed_ad_user_credential
short_description: Provision an AWS Managed Microsoft AD user credential
description:
  - Generates a unique password using AWS Secrets Manager or accepts an approved supplied password.
  - Sets or resets the password for one AWS Managed Microsoft AD user.
  - Optionally stores the credential in AWS Secrets Manager.
  - Never returns the plaintext password.
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
    description:
      - AWS Secrets Manager secret name for this user.
      - Required when store_secret is true.
    required: false
    type: str
  region:
    description: AWS Region containing the directory and optional secret.
    required: true
    type: str
  password_source:
    description: Source used for the directory password.
    type: str
    choices:
      - generated
      - supplied
    default: generated
  supplied_password:
    description:
      - Password supplied by the caller when password_source is supplied.
      - Intended for password material already protected by Ansible Vault or an equivalent secret source.
    required: false
    type: str
  password_length:
    description: Length of the generated random password.
    type: int
    default: 24
  store_secret:
    description:
      - Whether to persist the resulting username and password in AWS Secrets Manager.
      - Normally true for generated credentials and false for Vault-backed credentials.
    type: bool
    default: true
author:
  - IRE Platform Engineering
requirements:
  - boto3
  - botocore
"""

EXAMPLES = r"""
- name: Provision generated Managed AD credential
  ire_platform.aws.managed_ad_user_credential:
    directory_id: d-0123456789
    user_name: yog73018
    secret_name: ire/sandbox/ad-users/yog73018
    region: us-east-1
    password_source: generated
    store_secret: true

- name: Provision Vault-backed Managed AD credential
  ire_platform.aws.managed_ad_user_credential:
    directory_id: d-0123456789
    user_name: ire-vpn-vault-poc
    region: us-east-1
    password_source: supplied
    supplied_password: "{{ managed_ad_bootstrap_user_credentials['ire-vpn-vault-poc'].password }}"
    store_secret: false
"""

RETURN = r"""
user_name:
  description: Directory user whose credential was provisioned.
  returned: always
  type: str
secret_name:
  description: Secrets Manager name containing the credential when secret storage is enabled.
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
password_source:
  description: Credential source used by this execution.
  returned: always
  type: str
secret_stored:
  description: Whether this execution stored the credential in Secrets Manager.
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
            "secret_name": {"type": "str", "required": False, "default": ""},
            "region": {"type": "str", "required": True},
            "password_source": {
                "type": "str",
                "choices": ["generated", "supplied"],
                "default": "generated",
            },
            "supplied_password": {
                "type": "str",
                "required": False,
                "default": None,
                "no_log": True,
            },
            "password_length": {"type": "int", "default": 24},
            "store_secret": {"type": "bool", "default": True},
        },
        supports_check_mode=False,
    )

    if not BOTO3_AVAILABLE:
        module.fail_json(
            msg="boto3 and botocore are required in the execution environment."
        )

    params = module.params

    if params["password_source"] == "generated":
        if params["password_length"] < 16:
            module.fail_json(
                msg="password_length must be at least 16 characters."
            )

    if params["password_source"] == "supplied":
        if not params["supplied_password"]:
            module.fail_json(
                msg="supplied_password is required when password_source is supplied."
            )

    if params["store_secret"] and not params["secret_name"].strip():
        module.fail_json(
            msg="secret_name is required when store_secret is true."
        )

    result = {
        "changed": False,
        "user_name": params["user_name"],
        "secret_name": params["secret_name"],
        "secret_created": False,
        "password_changed": False,
        "password_source": params["password_source"],
        "secret_stored": False,
    }

    try:
        session = boto3.session.Session(region_name=params["region"])
        directory_client = session.client("ds")

        if params["password_source"] == "generated":
            secrets_client = session.client("secretsmanager")

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
        else:
            password = params["supplied_password"]

        if params["store_secret"]:
            secrets_client = session.client("secretsmanager")

            secret_value = json.dumps(
                {
                    "username": params["user_name"],
                    "password": password,
                    "directory_id": params["directory_id"],
                }
            )

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

            result["secret_stored"] = True

        directory_client.reset_user_password(
            DirectoryId=params["directory_id"],
            UserName=params["user_name"],
            NewPassword=password,
        )

        result["password_changed"] = True
        result["changed"] = True

        module.exit_json(**result)

    except (BotoCoreError, ClientError, KeyError, ValueError) as error:
        module.fail_json(msg=str(error), **result)


def main() -> None:
    """Module entry point."""
    run_module()


if __name__ == "__main__":
    main()
