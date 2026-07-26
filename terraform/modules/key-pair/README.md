# Key Pair Module

Registers existing SSH public keys with AWS as EC2 key pairs.

The module takes public keys as input rather than generating them. That is a deliberate security choice — see below.

---

## Why the module does not generate keys

Terraform can generate a keypair with the `tls_private_key` resource, and many examples do. This module does not, because **anything Terraform generates is written to state in plaintext**. A generated private key ends up stored in the state file, which is then replicated wherever state lives — S3, a backup, a CI artifact, a developer's laptop.

Taking a public key as input means the private half never enters Terraform at all. Only the public key is sent to AWS or stored in state, and the private key stays wherever the operator generated it.

Generate a key outside Terraform:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/management -C "ire-management"
```

Then pass the public half in.

---

## Usage

```hcl
module "key_pair" {
  source = "../../modules/key-pair"

  default_tags = {
    Environment = "Sandbox"
    Project     = "AWS-IRE"
    ManagedBy   = "Terraform"
  }

  key_pairs = {
    management = {
      public_key = file("~/.ssh/management.pub")
    }
  }
}
```

Reading a key from a local path makes the configuration machine-dependent. For anything shared or run in CI, pass the key material through a variable instead:

```hcl
variable "management_public_key" {
  description = "SSH public key for the management key pair."
  type        = string
}

module "key_pair" {
  source = "../../modules/key-pair"

  key_pairs = {
    management = {
      public_key = var.management_public_key
    }
  }
}
```

Then consume the output — note that `aws_instance.key_name` expects the key's **name**, not its ID:

```hcl
module "ec2" {
  source = "../../modules/ec2"

  instances = {
    app = {
      # ...
      key_name = module.key_pair.key_names["management"]
    }
  }
}
```

---

## Inputs

| Name | Type | Default | Required | Description |
|---|---|---|:---:|---|
| `key_pairs` | `map(object)` | `{}` | no | Key pairs to create. The map key becomes the AWS key pair name. |
| `default_tags` | `map(string)` | `{}` | no | Tags applied to every key pair, before per-key overrides. |

### `key_pairs` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `public_key` | `string` | required | OpenSSH-format public key material. |
| `tags` | `map(string)` | `{}` | Tags for this key pair, merged over `default_tags`. |

---

## Outputs

| Name | Type | Description |
|---|---|---|
| `key_names` | `map(string)` | Key name → AWS key pair name. This is what the `ec2` module consumes. |
| `key_ids` | `map(string)` | Key name → key pair ID. |

---

## Design notes

**The map key is the AWS key pair name.** What you write in Terraform is what appears in the console.

**Key pairs are not the only access path.** AWS Systems Manager Session Manager reaches instances without SSH keys, inbound ports, or a public IP, and it produces an auditable session log. For a recovery environment that is generally the better primary access method, with key pairs kept as a break-glass fallback.

---

## Terraform concepts used

| Concept | Where | Why it is used |
|---|---|---|
| `for_each` over a map | `key-pair.tf` | One key pair per named entry |
| `optional()` in object types | `variables.tf` | `tags` may be omitted entirely |
| Map comprehension + `merge()` | `locals.tf` | Precompute per-key tags with clear precedence |
| `for` comprehension in outputs | `outputs.tf` | Return names and IDs keyed by the caller's own names |

---

## Requirements

Inherited from the calling configuration. This module has no populated `versions.tf`; see the repository README's known limitations.

| Requirement | Version |
|---|---|
| Terraform | `>= 1.10.0` (as used by the sandbox environment) |
| AWS provider | `~> 6.0` |
