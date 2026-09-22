#!/usr/bin/python

from __future__ import annotations

import os
import tarfile
import tempfile
from pathlib import Path

from ansible.module_utils.basic import AnsibleModule

try:
    import boto3
    from botocore.exceptions import ClientError

    HAS_BOTO3 = True
except ImportError:
    HAS_BOTO3 = False


DOCUMENTATION = r'''
---
module: easyrsa_pki_archive
short_description: Restore or persist an EasyRSA PKI archive in Amazon S3
description:
  - Restores an EasyRSA PKI directory from an S3 archive.
  - Persists an EasyRSA PKI directory to S3 using SSE-KMS.
  - Does not expose PKI file contents in module output.
options:
  action:
    description:
      - Operation to perform.
    choices:
      - restore
      - persist
    required: true
    type: str
  bucket:
    description:
      - S3 bucket containing the PKI archive.
    required: true
    type: str
  key:
    description:
      - S3 object key containing the PKI archive.
    required: true
    type: str
  pki_path:
    description:
      - Local EasyRSA PKI directory.
    required: true
    type: path
  region:
    description:
      - AWS region.
    required: true
    type: str
  kms_key_arn:
    description:
      - KMS key ARN used for SSE-KMS when persisting.
    required: false
    type: str
author:
  - IRE Platform Engineering
'''

EXAMPLES = r'''
- name: Restore EasyRSA PKI
  ire_platform.aws.easyrsa_pki_archive:
    action: restore
    bucket: ire-private-artifacts
    key: ire/sandbox/client-vpn/easyrsa-pki.tar.gz
    pki_path: /tmp/ire-client-vpn/pki
    region: us-east-1

- name: Persist EasyRSA PKI
  ire_platform.aws.easyrsa_pki_archive:
    action: persist
    bucket: ire-private-artifacts
    key: ire/sandbox/client-vpn/easyrsa-pki.tar.gz
    pki_path: /tmp/ire-client-vpn/pki
    region: us-east-1
    kms_key_arn: arn:aws:kms:us-east-1:123456789012:key/example
'''

RETURN = r'''
exists:
  description: Whether the S3 PKI archive exists.
  returned: always
  type: bool
bucket:
  description: S3 bucket.
  returned: always
  type: str
key:
  description: S3 object key.
  returned: always
  type: str
etag:
  description: S3 object ETag when available.
  returned: when available
  type: str
version_id:
  description: S3 object version ID when versioning is enabled.
  returned: when available
  type: str
'''


def safe_extract(archive_path: str, destination: str) -> None:
    destination_path = Path(destination).resolve()

    with tarfile.open(archive_path, "r:gz") as archive:
        for member in archive.getmembers():
            member_path = (destination_path / member.name).resolve()

            try:
                member_path.relative_to(destination_path)
            except ValueError:
                raise ValueError(
                    f"Unsafe archive member outside PKI path: {member.name}"
                )

            if member.issym() or member.islnk():
                raise ValueError(
                    f"Archive links are not permitted: {member.name}"
                )

        archive.extractall(destination_path)


def restore_archive(module, s3, bucket, key, pki_path):
    try:
        metadata = s3.head_object(Bucket=bucket, Key=key)
    except ClientError as exc:
        code = exc.response.get("Error", {}).get("Code", "")

        if code in ("404", "NoSuchKey", "NotFound"):
            module.exit_json(
                changed=False,
                exists=False,
                bucket=bucket,
                key=key,
            )

        module.fail_json(
            msg=f"Failed to inspect EasyRSA PKI archive: {exc}"
        )

    os.makedirs(pki_path, mode=0o700, exist_ok=True)

    with tempfile.NamedTemporaryFile(suffix=".tar.gz") as temporary_archive:
        try:
            s3.download_file(
                bucket,
                key,
                temporary_archive.name,
            )

            safe_extract(
                temporary_archive.name,
                pki_path,
            )
        except (ClientError, tarfile.TarError, OSError, ValueError) as exc:
            module.fail_json(
                msg=f"Failed to restore EasyRSA PKI archive: {exc}"
            )

    module.exit_json(
        changed=True,
        exists=True,
        bucket=bucket,
        key=key,
        etag=metadata.get("ETag", "").strip('"'),
        version_id=metadata.get("VersionId"),
    )


def persist_archive(module, s3, bucket, key, pki_path, kms_key_arn):
    if not kms_key_arn:
        module.fail_json(
            msg="kms_key_arn is required when persisting the EasyRSA PKI archive"
        )

    if not os.path.isdir(pki_path):
        module.fail_json(
            msg=f"EasyRSA PKI path does not exist: {pki_path}"
        )

    ca_certificate = os.path.join(pki_path, "ca.crt")
    ca_private_key = os.path.join(pki_path, "private", "ca.key")

    if not os.path.isfile(ca_certificate):
        module.fail_json(
            msg="EasyRSA CA certificate is missing from the PKI path"
        )

    if not os.path.isfile(ca_private_key):
        module.fail_json(
            msg="EasyRSA CA private key is missing from the PKI path"
        )

    with tempfile.NamedTemporaryFile(suffix=".tar.gz") as temporary_archive:
        try:
            with tarfile.open(
                temporary_archive.name,
                "w:gz",
            ) as archive:
                for entry in sorted(os.listdir(pki_path)):
                    archive.add(
                        os.path.join(pki_path, entry),
                        arcname=entry,
                        recursive=True,
                    )

            with open(temporary_archive.name, "rb") as archive_file:
                response = s3.put_object(
                    Bucket=bucket,
                    Key=key,
                    Body=archive_file,
                    ServerSideEncryption="aws:kms",
                    SSEKMSKeyId=kms_key_arn,
                    ContentType="application/gzip",
                )
        except (ClientError, tarfile.TarError, OSError) as exc:
            module.fail_json(
                msg=f"Failed to persist EasyRSA PKI archive: {exc}"
            )

    module.exit_json(
        changed=True,
        exists=True,
        bucket=bucket,
        key=key,
        etag=response.get("ETag", "").strip('"'),
        version_id=response.get("VersionId"),
    )


def main():
    module = AnsibleModule(
        argument_spec=dict(
            action=dict(
                type="str",
                required=True,
                choices=["restore", "persist"],
            ),
            bucket=dict(
                type="str",
                required=True,
            ),
            key=dict(
                type="str",
                required=True,
            ),
            pki_path=dict(
                type="path",
                required=True,
            ),
            region=dict(
                type="str",
                required=True,
            ),
            kms_key_arn=dict(
                type="str",
                required=False,
                default="",
            ),
        ),
        supports_check_mode=False,
    )

    if not HAS_BOTO3:
        module.fail_json(
            msg="boto3 and botocore are required"
        )

    action = module.params["action"]
    bucket = module.params["bucket"]
    key = module.params["key"]
    pki_path = module.params["pki_path"]
    region = module.params["region"]
    kms_key_arn = module.params["kms_key_arn"]

    try:
        s3 = boto3.client(
            "s3",
            region_name=region,
        )
    except Exception as exc:
        module.fail_json(
            msg=f"Failed to create S3 client: {exc}"
        )

    if action == "restore":
        restore_archive(
            module,
            s3,
            bucket,
            key,
            pki_path,
        )

    persist_archive(
        module,
        s3,
        bucket,
        key,
        pki_path,
        kms_key_arn,
    )


if __name__ == "__main__":
    main()
