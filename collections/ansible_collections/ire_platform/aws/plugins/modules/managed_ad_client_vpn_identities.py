#!/usr/bin/python
"""Bootstrap Client VPN identities in AWS Managed Microsoft AD."""

from __future__ import annotations

import re
import time

DOCUMENTATION = r"""
---
module: managed_ad_client_vpn_identities
short_description: Bootstrap Client VPN identities in Managed Microsoft AD
description:
  - Locates one active AWS Managed Microsoft AD by DNS name.
  - Enables Directory Service Data access when required.
  - Creates one Active Directory security group and multiple users when absent.
  - Sets the supplied temporary password only for newly created users unless an
    explicit existing-password reset is requested.
  - Adds every requested user to the group and returns the group SID.
options:
  directory_name:
    description: Fully qualified DNS name of the Managed Microsoft AD.
    required: true
    type: str
  user_names:
    description: Unique SAM account names to create and add to the group.
    required: true
    type: list
    elements: str
  group_name:
    description: SAM account name of the Client VPN authorization group.
    required: true
    type: str
  temporary_password:
    description: Password applied during user creation or an explicit reset.
    required: true
    type: str
  reset_existing_password:
    description:
      - Explicitly reset the password when the user already exists.
      - Keep disabled for normal idempotent execution.
    type: bool
    default: false
  region:
    description: AWS Region containing the directory.
    required: true
    type: str
  wait_timeout_seconds:
    description: Maximum wait for Directory Service Data access to become enabled.
    type: int
    default: 600
  wait_delay_seconds:
    description: Delay between Directory Service Data status checks.
    type: int
    default: 10
author:
  - IRE Platform Engineering
requirements:
  - boto3
  - botocore
"""

EXAMPLES = r"""
- name: Bootstrap Client VPN identities
  ire_platform.aws.managed_ad_client_vpn_identities:
    directory_name: directory.example.com
    user_names:
      - proof.user
      - proof.user2
    group_name: IRE-Client-VPN-Users
    temporary_password: "{{ proof_user_password }}"
    region: us-east-1
"""

RETURN = r"""
directory_id:
  description: ID of the active Managed Microsoft AD.
  returned: always
  type: str
group_sid:
  description: SID of the Client VPN authorization group.
  returned: always
  type: str
users_created:
  description: SAM account names created by this execution.
  returned: always
  type: list
group_created:
  description: Whether this execution created the authorization group.
  returned: always
  type: bool
memberships_added:
  description: SAM account names added to the group by this execution.
  returned: always
  type: list
passwords_changed:
  description: SAM account names whose password was set or reset.
  returned: always
  type: list
data_access_enabled:
  description: Whether this execution requested Directory Service Data access.
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


def _find_directory(ds_client, directory_name: str) -> dict:
    matches = []
    next_token = None

    while True:
        request = {}
        if next_token:
            request["NextToken"] = next_token
        response = ds_client.describe_directories(**request)
        matches.extend(
            directory
            for directory in response.get("DirectoryDescriptions", [])
            if directory.get("Name", "").lower() == directory_name.lower()
        )
        next_token = response.get("NextToken")
        if not next_token:
            break

    if len(matches) != 1:
        raise ValueError(
            f"Expected exactly one directory named {directory_name}; found {len(matches)}."
        )
    if matches[0].get("Stage") != "Active":
        raise ValueError(
            f"Directory {matches[0].get('DirectoryId')} is "
            f"{matches[0].get('Stage')}, not Active."
        )
    return matches[0]


def _enable_data_access(ds_client, directory_id: str, timeout: int, delay: int) -> bool:
    status = ds_client.describe_directory_data_access(
        DirectoryId=directory_id
    ).get("DataAccessStatus")
    enabled_by_run = False

    if status == "Disabled":
        ds_client.enable_directory_data_access(DirectoryId=directory_id)
        enabled_by_run = True
    elif status in ("Disabling", "Failed"):
        raise ValueError(
            f"Directory Service Data access for {directory_id} is {status}."
        )

    deadline = time.monotonic() + timeout
    while status != "Enabled":
        if time.monotonic() >= deadline:
            raise TimeoutError(
                f"Directory Service Data access for {directory_id} did not become Enabled "
                f"within {timeout} seconds."
            )
        time.sleep(delay)
        status = ds_client.describe_directory_data_access(
            DirectoryId=directory_id
        ).get("DataAccessStatus")
        if status == "Failed":
            raise ValueError(
                f"Directory Service Data access for {directory_id} entered Failed state."
            )

    return enabled_by_run


def _describe_or_none(client, operation: str, **kwargs):
    try:
        return getattr(client, operation)(**kwargs)
    except ClientError as error:
        if _error_code(error) == "ResourceNotFoundException":
            return None
        raise


def _is_member(data_client, directory_id: str, group_name: str, user_name: str) -> bool:
    paginator = data_client.get_paginator("list_group_members")
    pages = paginator.paginate(
        DirectoryId=directory_id,
        SAMAccountName=group_name,
    )
    return any(
        member.get("MemberType") == "USER"
        and member.get("SAMAccountName", "").lower() == user_name.lower()
        for page in pages
        for member in page.get("Members", [])
    )


def run_module() -> None:
    module = AnsibleModule(
        argument_spec={
            "directory_name": {"type": "str", "required": True},
            "user_names": {
                "type": "list",
                "elements": "str",
                "required": True,
            },
            "group_name": {"type": "str", "required": True},
            "temporary_password": {"type": "str", "required": True, "no_log": True},
            "reset_existing_password": {"type": "bool", "default": False},
            "region": {"type": "str", "required": True},
            "wait_timeout_seconds": {"type": "int", "default": 600},
            "wait_delay_seconds": {"type": "int", "default": 10},
        },
        supports_check_mode=False,
    )

    if not BOTO3_AVAILABLE:
        module.fail_json(msg="boto3 and botocore are required in the execution environment.")

    params = module.params
    result = {
        "changed": False,
        "data_access_enabled": False,
        "group_created": False,
        "users_created": [],
        "passwords_changed": [],
        "memberships_added": [],
    }

    try:
        session = boto3.session.Session(region_name=params["region"])
        ds_client = session.client("ds")
        data_client = session.client("ds-data")

        directory = _find_directory(ds_client, params["directory_name"])
        directory_id = directory["DirectoryId"]
        result["directory_id"] = directory_id

        result["data_access_enabled"] = _enable_data_access(
            ds_client,
            directory_id,
            params["wait_timeout_seconds"],
            params["wait_delay_seconds"],
        )

        group = _describe_or_none(
            data_client,
            "describe_group",
            DirectoryId=directory_id,
            SAMAccountName=params["group_name"],
        )
        if group is None:
            group = data_client.create_group(
                DirectoryId=directory_id,
                SAMAccountName=params["group_name"],
                GroupScope="Global",
                GroupType="Security",
            )
            result["group_created"] = True
        result["group_sid"] = group["SID"]

        user_names = params["user_names"]
        normalized_user_names = [name.strip() for name in user_names]
        if not normalized_user_names or any(not name for name in normalized_user_names):
            raise ValueError("user_names must contain at least one non-empty name.")
        if any(
            re.fullmatch(r"[A-Za-z0-9._-]{1,20}", name) is None
            for name in normalized_user_names
        ):
            raise ValueError(
                "Each user name must contain 1-20 letters, numbers, dots, "
                "underscores, or hyphens."
            )
        if len({name.lower() for name in normalized_user_names}) != len(
            normalized_user_names
        ):
            raise ValueError("user_names must not contain duplicate names.")

        for user_name in normalized_user_names:
            user = _describe_or_none(
                data_client,
                "describe_user",
                DirectoryId=directory_id,
                SAMAccountName=user_name,
            )
            user_created = user is None
            if user_created:
                data_client.create_user(
                    DirectoryId=directory_id,
                    SAMAccountName=user_name,
                )
                result["users_created"].append(user_name)

            if user_created or params["reset_existing_password"]:
                ds_client.reset_user_password(
                    DirectoryId=directory_id,
                    UserName=user_name,
                    NewPassword=params["temporary_password"],
                )
                result["passwords_changed"].append(user_name)

            if not _is_member(
                data_client,
                directory_id,
                params["group_name"],
                user_name,
            ):
                data_client.add_group_member(
                    DirectoryId=directory_id,
                    GroupName=params["group_name"],
                    MemberName=user_name,
                )
                result["memberships_added"].append(user_name)

        result["changed"] = any(
            result[key]
            for key in (
                "data_access_enabled",
                "group_created",
                "users_created",
                "passwords_changed",
                "memberships_added",
            )
        )
        module.exit_json(**result)
    except (BotoCoreError, ClientError, TimeoutError, ValueError) as error:
        module.fail_json(msg=str(error), **result)


def main() -> None:
    run_module()


if __name__ == "__main__":
    main()
