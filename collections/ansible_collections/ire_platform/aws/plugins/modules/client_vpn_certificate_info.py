#!/usr/bin/python

from __future__ import annotations

from datetime import datetime, timezone

DOCUMENTATION = r'''
---
module: client_vpn_certificate_info
short_description: Validate an ACM certificate for AWS Client VPN
description:
  - Reads one existing ACM certificate.
  - Validates certificate state, validity window, and certificate-chain availability.
  - Does not create, import, modify, or delete certificates.
options:
  certificate_arn:
    description:
      - ARN of the ACM server certificate.
    required: true
    type: str
  region:
    description:
      - AWS Region containing the certificate.
    required: true
    type: str
requirements:
  - boto3
  - botocore
author:
  - IRE Platform Engineering
'''

EXAMPLES = r'''
- name: Inspect Client VPN server certificate
  ire_platform.aws.client_vpn_certificate_info:
    certificate_arn: arn:aws:acm:us-east-2:123456789012:certificate/...
    region: us-east-2
'''

RETURN = r'''
certificate:
  description: Safe ACM certificate metadata.
  returned: always
  type: dict
'''

try:
    import boto3
    from botocore.exceptions import BotoCoreError, ClientError
except ImportError:
    boto3 = None

from ansible.module_utils.basic import AnsibleModule


def main():
    module = AnsibleModule(
        argument_spec={
            "certificate_arn": {"type": "str", "required": True},
            "region": {"type": "str", "required": True},
        },
        supports_check_mode=True,
    )

    if boto3 is None:
        module.fail_json(
            msg="boto3 and botocore are required in the execution environment."
        )

    certificate_arn = module.params["certificate_arn"].strip()
    region = module.params["region"].strip()

    if not certificate_arn.startswith(f"arn:aws:acm:{region}:"):
        module.fail_json(
            msg="certificate_arn does not belong to the requested AWS Region."
        )

    try:
        session = boto3.session.Session(region_name=region)
        acm = session.client("acm")

        response = acm.describe_certificate(CertificateArn=certificate_arn)
        certificate = response["Certificate"]

        cert_response = acm.get_certificate(CertificateArn=certificate_arn)
        certificate_chain = cert_response.get("CertificateChain") or ""

        not_before = certificate.get("NotBefore")
        not_after = certificate.get("NotAfter")
        now = datetime.now(timezone.utc)

        valid_now = bool(
            not_before
            and not_after
            and not_before <= now <= not_after
        )

        result = {
            "certificate_arn": certificate.get("CertificateArn"),
            "domain_name": certificate.get("DomainName"),
            "status": certificate.get("Status"),
            "failure_reason": certificate.get("FailureReason"),
            "type": certificate.get("Type"),
            "issuer": certificate.get("Issuer"),
            "subject": certificate.get("Subject"),
            "key_algorithm": certificate.get("KeyAlgorithm"),
            "signature_algorithm": certificate.get("SignatureAlgorithm"),
            "not_before": (
                not_before.isoformat()
                if not_before
                else None
            ),
            "not_after": (
                not_after.isoformat()
                if not_after
                else None
            ),
            "valid_now": valid_now,
            "in_use_by": certificate.get("InUseBy", []),
            "certificate_chain_present": bool(certificate_chain.strip()),
        }

        module.exit_json(
            changed=False,
            certificate=result,
        )

    except (ClientError, BotoCoreError, KeyError) as exc:
        module.fail_json(
            msg=f"Unable to inspect ACM certificate: {exc}"
        )


if __name__ == "__main__":
    main()
