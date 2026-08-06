# EC2 Module

Creates EC2 instances from a map of instance definitions, with optional root volume configuration and consistent tagging.

The module is deliberately thin. It does not create security groups, key pairs, subnets, or IAM roles — those are inputs, supplied by the modules that own them. That keeps the interface small and the module reusable.

---

## Usage

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

module "ec2" {
  source = "../../modules/ec2"

  tags = {
    org_environment = "replace-with-approved-environment"
    org_project_name = "replace-with-approved-project-name"
    org_managed_by = "Terraform"
  }

  instances = {

    # Public instance: reachable from the internet, so it needs a
    # public IP and must sit in a subnet with an Internet Gateway route.
    management = {
      ami           = data.aws_ami.amazon_linux.id
      instance_type = "t3.micro"

      subnet_id                   = module.recovery_access.subnet_ids["admin-tools-a"]
      associate_public_ip_address = false

      key_name = module.key_pair.key_names["management"]

      vpc_security_group_ids = [
        module.security_group.security_group_ids["management"]
      ]
    }

    # Private instance with a custom encrypted root volume.
    core = {
      ami           = data.aws_ami.amazon_linux.id
      instance_type = "t3.micro"

      subnet_id = module.core_recovery.subnet_ids["recovery-services-a"]

      key_name = module.key_pair.key_names["management"]

      vpc_security_group_ids = [
        module.security_group.security_group_ids["core"]
      ]

      root_block_device = {
        volume_size = 50
        volume_type = "gp3"
        encrypted   = true
      }

      tags = {
        Role = "RecoveryTooling"
      }
    }
  }
}
```

Referencing the outputs:

```hcl
output "core_instance_id" {
  value = module.ec2.instance_ids["core"]
}

output "core_private_ip" {
  value = module.ec2.private_ips["core"]
}
```

---

## Inputs

| Name | Type | Default | Required | Description |
|---|---|---|:---:|---|
| `instances` | `map(object)` | `{}` | no | Instances to create. The map key becomes the `Name` tag. |
| `tags` | `map(string)` | `{}` | no | Tags applied to every instance, before per-instance overrides. |

### `instances` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `ami` | `string` | required | AMI ID. Usually from an `aws_ami` data source rather than hardcoded. |
| `instance_type` | `string` | required | Instance type, e.g. `t3.micro`. |
| `subnet_id` | `string` | required | Subnet to launch into. Determines the AZ and the effective route table. |
| `vpc_security_group_ids` | `list(string)` | `[]` | Security groups to attach. |
| `key_name` | `string` | `null` | EC2 key pair name. Omit for instances reached only via SSM. |
| `iam_instance_profile` | `string` | `null` | Instance profile name for an IAM role. |
| `private_ip` | `string` | `null` | Fixed private IP. Omit to let AWS assign one. |
| `associate_public_ip_address` | `bool` | `false` | Assign a public IP. Only meaningful in a subnet with an IGW route. |
| `root_block_device` | `object` | `null` | Root volume settings. Omit to use the AMI default. |
| `tags` | `map(string)` | `{}` | Tags for this instance, merged over the module-level `tags` input. |

### `root_block_device` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `volume_size` | `number` | required | Size in GiB. |
| `volume_type` | `string` | `"gp3"` | Volume type. |
| `encrypted` | `bool` | `true` | Encrypt at rest. Defaults on. |
| `delete_on_termination` | `bool` | `true` | Delete the volume when the instance terminates. |

---

## Outputs

| Name | Type | Description |
|---|---|---|
| `instance_ids` | `map(string)` | Instance name → instance ID. |
| `instance_arns` | `map(string)` | Instance name → ARN. |
| `private_ips` | `map(string)` | Instance name → private IP. |
| `public_ips` | `map(string)` | Instance name → public IP. Empty string for instances without one. |

Every output is keyed by the same name used in the `instances` input, so callers index by name rather than position.

---

## Design notes

**The map key is the identity.** It becomes the `Name` tag, the Terraform resource address, and the output key. Renaming a key replaces the instance, so treat keys as stable identifiers.

**Encryption is on by default.** `root_block_device.encrypted` defaults to `true`, so an explicitly configured root volume is encrypted unless someone opts out. Note the default only applies when `root_block_device` is supplied at all — omitting the block entirely leaves the AMI's own setting in place.

**Nothing validates network placement.** Setting `associate_public_ip_address = true` on a subnet with no Internet Gateway route produces an instance with an unreachable public IP. The module does not catch this; the caller is responsible for pairing subnets and settings correctly.

---

## Terraform concepts used

| Concept | Where | Why it is used |
|---|---|---|
| `for_each` over a map | `ec2.tf` | One instance per named entry, addressed by key |
| `dynamic` block | `ec2.tf` | Emit `root_block_device` zero or one times based on whether it was supplied |
| `try()` | `ec2.tf` | Resolve optional attributes to `null` so the provider leaves them unset |
| `optional()` in object types | `variables.tf` | Optional attributes, some with defaults, including a nested optional object |
| Map comprehension + `merge()` | `locals.tf` | Precompute per-instance tags with clear precedence |
| `for` comprehension in outputs | `outputs.tf` | Return maps keyed by instance name |

The `dynamic` block is the piece worth studying. Nested blocks cannot be set to `null` like arguments can, so generating the block from a collection — empty for "omit", one element for "include" — is the standard way to make a nested block conditional.

---

## Requirements

Inherited from the calling configuration. This module has no populated `versions.tf`; see the repository README's known limitations.

| Requirement | Version |
|---|---|
| Terraform | `>= 1.10.0` (as used by the sandbox environment) |
| AWS provider | `~> 6.0` |
