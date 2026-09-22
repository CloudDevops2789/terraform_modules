#!/usr/bin/python

from __future__ import annotations

DOCUMENTATION = r'''
---
module: client_vpn_certificate_import
short_description: Import a Client VPN server certificate into ACM
description:
  - Imports an existing server certificate, private key, and certificate chain into ACM.
  - Does not generate certificate material.
  - Does not return certificate or private-key contents.
options:
  certificate_path:
    description:
      - Path to the PEM encoded server certificate.
    required: true
    type: str
  private_key_path:
    description:
      - Path to the unencrypted PEM encoded private key.
    required: true
    type: str
  certificate_chain_path:
    description:
      - Path to the PEM encoded certificate chain.
    required: true
    type: str
  region:
    description:
      - AWS Region where the certificate will be imported.
    required: true
    type: str
requirements:
  - boto3
  - botocore
author:
  - IRE Platform Engineering
'''

EXAMPLES = r'''
- name: Import Client VPN certificate into ACM
  ire_platform.aws.client_vpn_certificate_import:
    certificate_path: /tmp/pki/issued/vpn.example.org.crt
    private_key_path: /tmp/pki/private/vpn.example.org.key
    certificate_chain_path: /tmp/pki/ca.crt
    region: us-east-2
'''

RETURN = r'''
certificate_arn:
  description: ARN of the imported ACM certificate.
  returned: always
  type: str
'''

import os

try:
    import boto3
    from botocore.exceptions import BotoCoreError, ClientError
except ImportError:
    boto3 = None

from ansible.module_utils.basic import AnsibleModule


def read_binary_file(module, path, description):
    if not os.path.isfile(path):
        module.fail_json(
            msg=f"{description} does not exist: {path}"
        )

    try:
        with open(path, "rb") as file_handle:
            return file_handle.read()
    except OSError as exc:
        module.fail_json(
            msg=f"Unable to read {description}: {exc}"
        )


def main():
    module = AnsibleModule(
        argument_spec={
            "certificate_path": {"type": "str", "required": True},
            "private_key_path": {"type": "str", "required": True},
            "certificate_chain_path": {"type": "str", "required": True},
            "region": {"type": "str", "required": True},
        },
        supports_check_mode=False,
    )

    if boto3 is None:
        module.fail_json(
            msg="boto3 and botocore are required in the execution environment."
        )

    certificate = read_binary_file(
        module,
        module.params["certificate_path"],
        "server certificate",
    )
    private_key = read_binary_file(
        module,
        module.params["private_key_path"],
        "private key",
    )
    certificate_chain = read_binary_file(
        module,
        module.params["certificate_chain_path"],
        "certificate chain",
    )

    try:
        session = boto3.session.Session(
            region_name=module.params["region"]
        )
        acm = session.client("acm")

        response = acm.import_certificate(
            Certificate=certificate,
            PrivateKey=private_key,
            CertificateChain=certificate_chain,
        )

        module.exit_json(
            changed=True,
            certificate_arn=response["CertificateArn"],
        )

    except (ClientError, BotoCoreError, KeyError) as exc:
        module.fail_json(
            msg=f"Unable to import Client VPN certificate into ACM: {exc}"
        )


if __name__ == "__main__":
    main()
