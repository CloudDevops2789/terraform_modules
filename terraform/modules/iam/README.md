# IAM Module

Reusable Terraform module for creating AWS IAM roles, managed-policy
attachments, inline policies, permissions boundaries, and optional EC2
instance profiles.

The module is intentionally workload-agnostic. IAM trust and permission
decisions remain with the calling environment.

## Purpose

Use this module when Terraform is authorized to create IAM resources.

Organizations that centrally manage IAM can instead create approved roles and
instance profiles outside this module and pass the resulting role or profile
names to workload configurations.

This allows reusable workloads to support both Terraform-managed and
enterprise-managed IAM.

## Capabilities

- Multiple IAM roles from a keyed map
- Caller-defined trust policies
- AWS-managed or customer-managed policy attachments
- Inline IAM policies
- Optional permissions boundaries
- Configurable maximum session duration
- Optional EC2 instance profiles
- Common and role-specific tags
- Stable logical addressing through `for_each`

## Architecture

~~~mermaid
flowchart TD
    Caller[Terraform Caller] --> IAM[IAM Module]
    IAM --> Role[IAM Role]
    Role --> Managed[Managed Policy Attachments]
    Role --> Inline[Inline Policies]
    Role --> Profile[Optional EC2 Instance Profile]
~~~

## Inputs

### roles

Map of IAM role definitions.

Supported attributes:

| Attribute | Required | Description |
|---|---:|---|
| `name` | No | Physical IAM role name. Defaults to the logical map key. |
| `description` | No | IAM role description. |
| `path` | No | IAM path. Defaults to `/`. |
| `assume_role_policy` | Yes | IAM trust policy as valid JSON. |
| `permissions_boundary` | No | Permissions-boundary ARN. |
| `max_session_duration` | No | Session duration from 3600 through 43200 seconds. |
| `force_detach_policies` | No | Controls policy detachment during deletion. |
| `managed_policy_arns` | No | Managed policy ARNs to attach. |
| `inline_policies` | No | Map of inline policy name to policy JSON. |
| `create_instance_profile` | No | Creates an EC2 instance profile when true. |
| `instance_profile_name` | No | Explicit instance-profile name. |
| `tags` | No | Role-specific tags. |

### tags

Common tags applied to IAM roles and instance profiles.

Role-specific tags are merged with common tags.

## Generic EC2 Role Example

    data "aws_partition" "current" {}

    module "iam" {
      source = "../../modules/iam"

      roles = {
        application_compute = {
          name        = "org-application-compute"
          description = "Application compute role"

          assume_role_policy = jsonencode({
            Version = "2012-10-17"
            Statement = [
              {
                Effect = "Allow"
                Principal = {
                  Service = "ec2.amazonaws.com"
                }
                Action = "sts:AssumeRole"
              }
            ]
          })

          managed_policy_arns = [
            "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
          ]

          create_instance_profile = true
        }
      }

      tags = {
        org_environment = "recovery"
        org_managed_by  = "Terraform"
      }
    }

## Systems Manager Example

Systems Manager is one possible consumer of this generic module. Nothing inside
the IAM module is specific to Systems Manager.

    data "aws_partition" "current" {}

    module "iam" {
      source = "../../modules/iam"

      roles = {
        managed_compute = {
          name = "org-managed-compute"

          assume_role_policy = jsonencode({
            Version = "2012-10-17"
            Statement = [
              {
                Effect = "Allow"
                Principal = {
                  Service = "ec2.amazonaws.com"
                }
                Action = "sts:AssumeRole"
              }
            ]
          })

          managed_policy_arns = [
            "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
          ]

          create_instance_profile = true
        }
      }
    }

An organization can substitute an approved customer-managed policy where a
more restrictive permission model is required.

## Centrally Managed IAM Pattern

The module is optional from the workload perspective.

Where an IAM or security team owns role creation, the workflow can be:

~~~mermaid
flowchart TD
    Governance[IAM Governance Process] --> Role[Approved EC2 Role]
    Role --> Profile[Approved Instance Profile]
    Profile --> Workload[Terraform Workload Consumes Profile Name]
~~~

This avoids requiring an application or automation deployment role to have
broad IAM-creation permissions.

## Permissions Boundary Example

    roles = {
      application_compute = {
        assume_role_policy = local.ec2_trust_policy

        permissions_boundary =
          "arn:aws:iam::123456789012:policy/org-permissions-boundary"
      }
    }

Values shown in examples are illustrative and must be replaced with approved
environment values.

## Inline Policy Example

    roles = {
      application_compute = {
        assume_role_policy = local.ec2_trust_policy

        inline_policies = {
          read_artifacts = jsonencode({
            Version = "2012-10-17"
            Statement = [
              {
                Effect   = "Allow"
                Action   = ["s3:GetObject"]
                Resource = ["arn:aws:s3:::example-artifact-bucket/*"]
              }
            ]
          })
        }
      }
    }

## Outputs

The module exposes:

- `roles`
- `role_names`
- `role_arns`
- `instance_profile_names`
- `instance_profile_arns`

Outputs are keyed by the logical role key supplied by the caller.

## Security Considerations

IAM trust policies and permission policies are security decisions owned by the
calling environment.

Apply least privilege.

Avoid broad wildcard permissions unless explicitly required and approved.

Use permissions boundaries when required by organizational governance.

Prefer IAM roles and temporary credentials over long-lived AWS credentials.

Creating an EC2 instance profile does not automatically authorize an operator
to access the instance. Operator authorization, privileged-access controls,
network connectivity, and workload authorization remain separate concerns.

## Lifecycle

IAM resources commonly have a different lifecycle from temporary compute.

For persistent platform designs, the IAM role and instance profile can remain
available while temporary EC2 resources are created and removed independently.

The calling environment owns that lifecycle decision.

## Validation

A reusable module test is located at:

    terraform/environments/module-tests/iam

The test demonstrates:

- EC2 trust policy
- managed-policy attachment
- optional instance-profile creation
- reusable tagging

The module remains independent of the example workload.
