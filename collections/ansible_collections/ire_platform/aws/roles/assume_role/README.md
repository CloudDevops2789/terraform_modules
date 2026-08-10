# Assume Role

## Overview

The `assume_role` role provides a standardized mechanism for obtaining temporary AWS Security Token Service (STS) credentials by assuming an IAM role.

This role is intended to be the first role executed by AWS automation workflows and establishes a temporary security context for all subsequent AWS operations.

Using temporary credentials instead of long-lived IAM user credentials aligns with AWS security best practices and enables centralized permission management through IAM roles.

---

## Features

- Assumes an AWS IAM Role using AWS Security Token Service (STS)
- Generates unique session names for auditability
- Returns temporary AWS credentials
- Supports execution from:
  - Ansible Automation Platform (AAP)
  - AWX
  - GitHub Actions
  - Jenkins
  - Local Ansible execution
- Designed for enterprise reusable Ansible Collections

---

## Architecture

```
Bootstrap IAM User
        │
        ▼
STS AssumeRole
        │
        ▼
Temporary Credentials
        │
        ▼
AWS Resource Roles
```

The bootstrap IAM user requires only the permissions necessary to perform `sts:AssumeRole`.

All infrastructure provisioning is performed using temporary credentials obtained from the assumed IAM role.

---

## Requirements

- Ansible Core 2.16+
- amazon.aws Collection
- boto3
- botocore

---

## Variables

| Variable | Required | Description |
|-----------|----------|-------------|
| assume_role_role_arn | Yes | IAM Role ARN to assume |
| assume_role_aws_region | Yes | AWS Region |
| assume_role_application_name | No | Used when generating the STS session name |
| assume_role_session_duration_seconds | No | STS session duration |
| assume_role_external_id | No | External ID if required by the trust policy |

---

## Returned Facts

After successful execution, the role exposes the following facts:

```yaml
assume_role_aws_auth:
  access_key:
  secret_key:
  session_token:
  expiration:
  region:
```

These credentials are intended to be consumed by subsequent AWS roles.

---

## Example

```yaml
---
- hosts: localhost
  gather_facts: false

  vars:
    assume_role_role_arn: arn:aws:iam::123456789012:role/example-role
    assume_role_aws_region: us-east-1
    assume_role_application_name: network

  roles:
    - ire_platform.aws.assume_role
```

---

## Example Workflow

```
Playbook
    │
    ▼
assume_role
    │
    ▼
Temporary AWS Credentials
    │
    ├── vpc
    ├── subnet
    ├── security_group
    ├── s3_bucket
    ├── dynamodb
    ├── ec2
    └── ...
```

The `assume_role` role should be executed once at the beginning of a workflow. Subsequent roles consume the temporary credentials without requiring additional role assumption.

---

## Security Considerations

- Do not use long-lived IAM user credentials for resource provisioning.
- Grant the bootstrap IAM user only the `sts:AssumeRole` permission required to obtain temporary credentials.
- Scope IAM role permissions using the principle of least privilege.
- Avoid logging or exposing temporary credentials.
- Configure an appropriate STS session duration based on operational requirements.

---

## Future Enhancements

- Support multiple AWS accounts
- Support chained role assumption
- MFA-enabled role assumption
- External ID support for cross-account access
- Integration with enterprise secrets management platforms
