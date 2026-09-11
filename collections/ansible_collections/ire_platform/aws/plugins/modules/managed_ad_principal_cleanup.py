#!/usr/bin/python
"""Remove Managed AD memberships and optionally delete users."""

from __future__ import annotations

import re

DOCUMENTATION = r"""
---
module: managed_ad_principal_cleanup
short_description: Remove Managed AD memberships and optionally delete users
description:
  - Removes requested AWS Managed Microsoft AD users from one security group.
  - Optionally deletes requested directory users after membership cleanup.
  - Treats already absent users and memberships as idempotent outcomes.
  - Does not delete the group.
options:
  directory_id:
    description: AWS Managed Microsoft AD directory ID.
    required: true
    type: str
  group_name:
    description: SAM account name of the Managed AD security group.
    required: true
    type: str
  user_names:
    description: Directory SAM account names to clean up.
    required: true
    type: list
    elements: str
  delete_users:
    description: Whether directory users should be deleted after membership removal.
    required: true
    type: bool
  region:
    description: AWS Region containing the directory.
    required: true
    type: str
author:
  - IRE Platform Engineering
requirements:
  - boto3
  - botocore
"""

EXAMPLES = r"""
- name: Revoke Managed AD group access
  ire_platform.aws.managed_ad_principal_cleanup:
    directory_id: d-0123456789
    group_name: IRE_ClientVPN_Users
    user_names:
      - user01
      - user02
    delete_users: false
    region: us-east-1

- name: Fully remove Managed AD users
  ire_platform.aws.managed_ad_principal_cleanup:
    directory_id: d-0123456789
    group_name: IRE_ClientVPN_Users
    user_names:
      - user01
      - user02
    delete_users: true
    region: us-east-1
"""

RETURN = r"""
memberships_removed:
  description: Users removed from the group during this execution.
  returned: always
  type: list
users_deleted:
  description: Directory users deleted during this execution.
  returned: always
  type: list
users_missing:
  description: Requested users that did not exist.
  returned: always
  type: list
group_missing:
  description: Whether the requested group was already absent.
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
    return error.response.get("Error", {}).get("Code", "Unknown")


def _describe_user_or_none(client, directory_id: str, user_name: str):
    try:
        return client.describe_user(
            DirectoryId=directory_id,
            SAMAccountName=user_name,
        )
    except ClientError as error:
        if _error_code(error) == "ResourceNotFoundException":
            return None
        raise


def _group_members(client, directory_id: str, group_name: str):
    members = set()
    next_token = None

    while True:
        request = {
            "DirectoryId": directory_id,
            "SAMAccountName": group_name,
        }

        if next_token:
            request["NextToken"] = next_token

        try:
            response = client.list_group_members(**request)
        except ClientError as error:
            if _error_code(error) == "ResourceNotFoundException":
                return None
            raise

        for member in response.get("Members", []):
            if member.get("MemberType") == "USER":
                name = member.get("SAMAccountName")
                if name:
                    members.add(name.lower())

        next_token = response.get("NextToken")
        if not next_token:
            break

    return members


def run_module() -> None:
    module = AnsibleModule(
        argument_spec={
            "directory_id": {"type": "str", "required": True},
            "group_name": {"type": "str", "required": True},
            "user_names": {
                "type": "list",
                "elements": "str",
                "required": True,
            },
            "delete_users": {"type": "bool", "required": True},
            "region": {"type": "str", "required": True},
        },
        supports_check_mode=False,
    )

    if not BOTO3_AVAILABLE:
        module.fail_json(
            msg="boto3 and botocore are required in the execution environment."
        )

    params = module.params

    directory_id = params["directory_id"].strip()
    group_name = params["group_name"].strip()
    user_names = [name.strip() for name in params["user_names"]]

    if re.fullmatch(r"d-[0-9a-f]{10}", directory_id) is None:
        module.fail_json(msg="directory_id is not a valid AWS Directory Service ID.")

    if not group_name or len(group_name) > 64:
        module.fail_json(msg="group_name must contain 1-64 characters.")

    if not user_names or any(not name for name in user_names):
        module.fail_json(msg="user_names must contain at least one non-empty user.")

    if any(
        re.fullmatch(r"[A-Za-z0-9._-]{1,20}", name) is None
        for name in user_names
    ):
        module.fail_json(
            msg=(
                "Each user name must contain 1-20 letters, numbers, dots, "
                "underscores, or hyphens."
            )
        )

    if len({name.lower() for name in user_names}) != len(user_names):
        module.fail_json(msg="user_names must not contain duplicate values.")

    result = {
        "changed": False,
        "group_missing": False,
        "memberships_removed": [],
        "users_deleted": [],
        "users_missing": [],
    }

    try:
        session = boto3.session.Session(region_name=params["region"])
        data_client = session.client("ds-data")

        existing_members = _group_members(
            data_client,
            directory_id,
            group_name,
        )
        if existing_members is None:
            result["group_missing"] = True
            existing_members = set()

        for user_name in user_names:
            user = _describe_user_or_none(
                data_client,
                directory_id,
                user_name,
            )

            if user is None:
                result["users_missing"].append(user_name)
                continue

            if user_name.lower() in existing_members:
                data_client.remove_group_member(
                    DirectoryId=directory_id,
                    GroupName=group_name,
                    MemberName=user_name,
                )
                result["memberships_removed"].append(user_name)

            if params["delete_users"]:
                data_client.delete_user(
                    DirectoryId=directory_id,
                    SAMAccountName=user_name,
                )
                result["users_deleted"].append(user_name)

        result["changed"] = bool(
            result["memberships_removed"] or result["users_deleted"]
        )

        module.exit_json(**result)

    except (BotoCoreError, ClientError, ValueError) as error:
        module.fail_json(msg=str(error), **result)


def main() -> None:
    run_module()


if __name__ == "__main__":
    main()
