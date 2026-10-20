#!/usr/bin/python
"""Publish an operational notification to Amazon SNS."""

from __future__ import annotations

import re

DOCUMENTATION = r"""
---
module: sns_publish
short_description: Publish an IRE operational notification to Amazon SNS
description:
  - Publishes a message to an existing Amazon SNS standard topic.
  - Supports an optional SNS subject.
  - Does not create topics or subscriptions.
options:
  topic_arn:
    description: ARN of the SNS topic.
    required: true
    type: str
  message:
    description: Notification message body.
    required: true
    type: str
  subject:
    description: Optional notification subject. SNS permits up to 100 characters.
    required: false
    type: str
  region:
    description: AWS Region containing the SNS topic.
    required: true
    type: str
author:
  - IRE Platform Engineering
requirements:
  - boto3
  - botocore
"""

EXAMPLES = r"""
- name: Publish IRE recovery notification
  ire_platform.aws.sns_publish:
    topic_arn: arn:aws:sns:us-east-1:123456789012:ire-notifications
    subject: IRE Recovery Notification
    message: Recovery validation completed successfully.
    region: us-east-1
"""

RETURN = r"""
message_id:
  description: SNS message identifier returned by AWS.
  returned: always
  type: str
topic_arn:
  description: SNS topic ARN used for the publish operation.
  returned: always
  type: str
"""

try:
    import boto3
    from botocore.exceptions import BotoCoreError, ClientError

    BOTO3_AVAILABLE = True
except ImportError:
    BOTO3_AVAILABLE = False

from ansible.module_utils.basic import AnsibleModule


def run_module() -> None:
    module = AnsibleModule(
        argument_spec={
            "topic_arn": {"type": "str", "required": True},
            "message": {"type": "str", "required": True},
            "subject": {"type": "str", "required": False, "default": None},
            "region": {"type": "str", "required": True},
        },
        supports_check_mode=False,
    )

    if not BOTO3_AVAILABLE:
        module.fail_json(
            msg="boto3 and botocore are required in the execution environment."
        )

    topic_arn = module.params["topic_arn"].strip()
    message = module.params["message"].strip()
    subject = module.params["subject"]
    region = module.params["region"].strip()

    if re.fullmatch(
        r"arn:[^:]+:sns:[^:]+:[0-9]{12}:[A-Za-z0-9_-]+",
        topic_arn,
    ) is None:
        module.fail_json(msg="topic_arn is not a valid SNS topic ARN.")

    if not message:
        module.fail_json(msg="message must not be empty.")

    if not region:
        module.fail_json(msg="region must not be empty.")

    if subject is not None:
        subject = subject.strip()

        if not subject:
            module.fail_json(msg="subject must not be empty when supplied.")

        if len(subject) > 100:
            module.fail_json(msg="subject must not exceed 100 characters.")

    try:
        session = boto3.session.Session(region_name=region)
        sns_client = session.client("sns")

        request = {
            "TopicArn": topic_arn,
            "Message": message,
        }

        if subject:
            request["Subject"] = subject

        response = sns_client.publish(**request)

    except (BotoCoreError, ClientError) as error:
        module.fail_json(
            msg=f"Failed to publish SNS notification: {error}"
        )

    message_id = response.get("MessageId")

    if not message_id:
        module.fail_json(
            msg="SNS publish succeeded but AWS did not return a MessageId."
        )

    module.exit_json(
        changed=True,
        message_id=message_id,
        topic_arn=topic_arn,
    )


def main() -> None:
    run_module()


if __name__ == "__main__":
    main()
