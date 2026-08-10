# S3 Bucket

## Overview

The `s3_bucket` role creates and configures an Amazon S3 bucket used to
bootstrap Terraform remote state.

Terraform remains responsible for provisioning the AWS IRE infrastructure.
This Ansible role only creates the backend infrastructure required before
`terraform init` can use remote state.

## Purpose

The expected workflow is:

AAP / Operator
  -> ire_platform.aws.assume_role
  -> assume_role_aws_auth
  -> s3_bucket_aws_auth
  -> ire_platform.aws.s3_bucket
  -> Terraform backend S3 bucket

## Authentication

The role does not perform IAM role assumption.

Temporary AWS credentials must be supplied through `s3_bucket_aws_auth`.

The normal source of these credentials is the
`ire_platform.aws.assume_role` role.

Example role mapping:

    - role: ire_platform.aws.assume_role

    - role: ire_platform.aws.s3_bucket
      vars:
        s3_bucket_aws_auth: "{{ assume_role_aws_auth }}"

## Features

The role supports:

- S3 bucket creation
- S3 bucket deletion when explicitly requested
- Versioning
- S3 Object Lock
- SSE-S3 encryption
- AWS KMS encryption
- S3 Public Access Block
- Default and caller-provided tags
- Controlled force deletion
- Structured role outputs
- Temporary STS authentication

## Requirements

- Ansible Core 2.16+
- amazon.aws collection
- boto3
- botocore
- Appropriate AWS IAM permissions

## Variables

### Authentication

`s3_bucket_aws_auth`

Temporary AWS authentication information supplied by the calling workflow.

### Bucket configuration

`s3_bucket_name`

S3 bucket name. Required.

`s3_bucket_region`

AWS Region where the bucket is created.

Default: `us-east-1`

`s3_bucket_state`

Desired bucket state.

Supported values:

- `present`
- `absent`

Default: `present`

### Data protection

`s3_bucket_versioning`

Enables S3 versioning.

Default: `true`

`s3_bucket_object_lock`

Enables S3 Object Lock.

Default: `true`

`s3_bucket_object_lock_mode`

Object Lock retention mode.

Default: `GOVERNANCE`

`s3_bucket_object_lock_retention_days`

Default Object Lock retention period.

Default: `30`

### Encryption

`s3_bucket_encryption`

Supported values:

- `AES256`
- `aws:kms`

Default: `AES256`

`s3_bucket_kms_key_id`

KMS key identifier when `s3_bucket_encryption` is `aws:kms`.

### Public access

`s3_bucket_public_access_block`

Enables S3 Public Access Block controls.

Default: `true`

### Destructive operations

`s3_bucket_force_destroy`

Allows bucket contents to be removed when deleting the bucket.

Default: `false`

This should remain disabled unless destructive removal is explicitly required.

### Tags

`s3_bucket_default_tags`

Default tags applied by the role.

`s3_bucket_tags`

Additional caller-provided tags.

Caller-provided tags take precedence over matching default tag keys.

## Outputs

After successful execution, the role publishes `s3_bucket_outputs`.

It contains:

- `name`
- `arn`
- `region`
- `versioning`
- `object_lock`
- `encryption`

These values can be consumed by later workflow steps.

## Terraform Backend Workflow

The intended bootstrap sequence is:

1. AAP starts the automation job.
2. `ire_platform.aws.assume_role` obtains temporary STS credentials.
3. The credentials are passed to `ire_platform.aws.s3_bucket`.
4. The Terraform backend bucket is created or validated.
5. Terraform can then execute `terraform init`.
6. Terraform creates and manages the remote state object.

The Ansible role does not provision the IRE infrastructure itself.

## Security Considerations

- Never store AWS credentials in source code.
- Use temporary IAM role credentials.
- Keep S3 Public Access Block enabled.
- Keep versioning enabled for Terraform state.
- Use AWS KMS encryption when required by enterprise policy.
- Treat `s3_bucket_force_destroy` as a destructive control.
- Configure Object Lock retention according to recovery and compliance policy.
- Never print temporary access keys, secret keys, or session tokens.
- Apply least-privilege IAM permissions to the AAP execution role.

## Example

A typical playbook uses:

    roles:
      - role: ire_platform.aws.assume_role

      - role: ire_platform.aws.s3_bucket
        vars:
          s3_bucket_aws_auth: "{{ assume_role_aws_auth }}"

Environment-specific values such as the IAM role ARN, Region, and bucket name
should be supplied by AAP, inventory, or runtime variables rather than being
hardcoded in this collection.
