#!/usr/bin/python
"""Create Managed AD group, users and memberships through AWS APIs."""

from __future__ import annotations

import re

DOCUMENTATION = r"""
---
module: managed_ad_principals
short_description: Bootstrap Managed AD users, group and memberships
description:
  - Creates one AWS Managed Microsoft AD security group when absent.
  - Creates requested directory users when absent.
  - Adds requested users to the group when membership is absent.
  - Returns the group SID and lifecycle result metadata.
  - Does not manage passwords.
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
    description: Directory SAM account names to create and add to the group.
    required: true
    type: list
    elements: str
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
- name: Bootstrap Managed AD principals
  ire_platform.aws.managed_ad_principals:
    directory_id: d-0123456789
    group_name: IRE_ClientVPN_Users
    user_names:
      - user01
      - user02
    region: us-east-1
"""

RETURN = r"""
group_sid:
  description: SID of the Managed AD security group.
  returned: always
  type: str
group_created:
  description: Whether this execution created the group.
  returned: always
  type: bool
users_created:
  description: Users created during this execution.
  returned: always
  type: list
users_existing:
  description: Users that already existed.
  returned: always
  type: list
memberships_added:
  description: Users added to the group during this execution.
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


def _describe_or_none(client, operation: str, **kwargs):
    try:
        return getattr(client, operation)(**kwargs)
    except ClientError as error:
        if _error_code(error) == "ResourceNotFoundException":
            return None
        raise


def _group_members(client, directory_id: str, group_name: str) -> set[str]:
    members = set()
    next_token = None

    while True:
        request = {
            "DirectoryId": directory_id,
            "SAMAccountName": group_name,
        }

        if next_token:
            request["NextToken"] = next_token

        response = client.list_group_members(**request)

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
            "region": {"type": "str", "required": True},
            "operation": {
                "type": "str",
                "choices": ["reconcile", "lookup"],
                "default": "reconcile",
            },
        },
        supports_check_mode=False,
    )

    if not BOTO3_AVAILABLE:
        module.fail_json(
            msg="boto3 and botocore are required in the execution environment."
        )

    params = module.params

    operation = params["operation"]
    directory_id = params["directory_id"].strip()
    group_name = params["group_name"].strip()
    user_names = [name.strip() for name in params["user_names"]]

    if re.fullmatch(r"d-[0-9a-f]{10}", directory_id) is None:
        module.fail_json(msg="directory_id is not a valid AWS Directory Service ID.")

    if not group_name or len(group_name) > 64:
        module.fail_json(msg="group_name must contain 1-64 characters.")

    # User reconciliation inputs are required only for the mutating operation.
    # Lookup intentionally accepts an empty user list because it reads only the
    # existing Managed AD authorization group and never changes principals.
    if operation == "reconcile":
        if not user_names or any(not name for name in user_names):
            module.fail_json(
                msg="user_names must contain at least one non-empty user."
            )

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
            module.fail_json(
                msg="user_names must not contain duplicate values."
            )

    result = {
        "changed": False,
        "group_created": False,
        "users_created": [],
        "users_existing": [],
        "memberships_added": [],
    }

    try:
        session = boto3.session.Session(region_name=params["region"])
        data_client = session.client("ds-data")

        ########################################################################
        # Group
        ########################################################################

        group = _describe_or_none(
            data_client,
            "describe_group",
            DirectoryId=directory_id,
            SAMAccountName=group_name,
        )

        ########################################################################
        # Read-Only Group Lookup
        #
        # Destroy workflows require the existing Client VPN authorization-group
        # SID but must never recreate directory objects while tearing down the
        # environment.
        ########################################################################

        if operation == "lookup":
            if group is None:
                module.fail_json(
                    msg=(
                        f"Managed AD group {group_name} does not exist; "
                        "lookup will not create it."
                    ),
                    **result,
                )

            group_sid = group.get("SID")

            if not group_sid:
                group = data_client.describe_group(
                    DirectoryId=directory_id,
                    SAMAccountName=group_name,
                )
                group_sid = group.get("SID")

            if not group_sid:
                module.fail_json(
                    msg=f"Managed AD group {group_name} did not expose a SID.",
                    **result,
                )

            result["group_sid"] = group_sid
            module.exit_json(**result)

        ########################################################################
        # Reconcile
        ########################################################################

        if group is None:
            group = data_client.create_group(
                DirectoryId=directory_id,
                SAMAccountName=group_name,
                GroupScope="Global",
                GroupType="Security",
            )
            result["group_created"] = True

        group_sid = group.get("SID")

        if not group_sid:
            group = data_client.describe_group(
                DirectoryId=directory_id,
                SAMAccountName=group_name,
            )
            group_sid = group.get("SID")

        if not group_sid:
            raise ValueError(
                f"Managed AD group {group_name} did not expose a SID."
            )

        result["group_sid"] = group_sid

        ########################################################################
        # Users
        ########################################################################

        for user_name in user_names:
            user = _describe_or_none(
                data_client,
                "describe_user",
                DirectoryId=directory_id,
                SAMAccountName=user_name,
            )

            if user is None:
                data_client.create_user(
                    DirectoryId=directory_id,
                    SAMAccountName=user_name,
                )
                result["users_created"].append(user_name)
            else:
                result["users_existing"].append(user_name)

        ########################################################################
        # Memberships
        ########################################################################

        existing_members = _group_members(
            data_client,
            directory_id,
            group_name,
        )

        for user_name in user_names:
            if user_name.lower() in existing_members:
                continue

            data_client.add_group_member(
                DirectoryId=directory_id,
                GroupName=group_name,
                MemberName=user_name,
            )
            result["memberships_added"].append(user_name)

        result["changed"] = any(
            (
                result["group_created"],
                result["users_created"],
                result["memberships_added"],
            )
        )

        module.exit_json(**result)

    except (BotoCoreError, ClientError, ValueError) as error:
        module.fail_json(msg=str(error), **result)


def main() -> None:
    run_module()


if __name__ == "__main__":
    main()
