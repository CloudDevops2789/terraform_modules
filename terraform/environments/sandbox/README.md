# Sandbox environment configuration

This directory contains Git-controlled, non-sensitive desired state for the
Sandbox environment. It is configuration consumed by AAP/AWX; it is not a
Terraform root and does not own state.

## Authoritative files

```text
terraform/environments/sandbox/
├── config/
│   ├── common-tags.tfvars
│   ├── persistent.tfvars
│   ├── platform.tfvars
│   ├── platform-network-policy.tfvars
│   ├── identity.tfvars
│   └── recovery.tfvars
└── keys/
    └── ire-lab-admin.pub
```

| File | Consumer | Purpose |
|---|---|---|
| `common-tags.tfvars` | All stacks | Customer-neutral `org_*` tagging contract |
| `persistent.tfvars` | Persistent | Optional long-lived vault and logging-KMS capabilities |
| `platform.tfvars` | Platform | Network topology, access plane, SSM and service placement |
| `platform-network-policy.tfvars` | Platform | Security-group and Network Firewall policy |
| `identity.tfvars` | Identity | Directory enablement and Platform placement selection |
| `recovery.tfvars` | Recovery | Temporary workloads, access, backup intent and placement |

AAP resolves these filenames through
`playbooks/vars/terraform_stack_bindings.yml`. It resolves the deployment root
separately under `terraform/stacks/<stack>`.

## Lifecycle roots and state

| Stack | Root | Backend key |
|---|---|---|
| Persistent | `terraform/stacks/persistent` | `ire/sandbox/persistent/terraform.tfstate` |
| Platform | `terraform/stacks/platform` | `ire/sandbox/platform/terraform.tfstate` |
| Identity | `terraform/stacks/identity` | `ire/sandbox/identity/terraform.tfstate` |
| Recovery | `terraform/stacks/recovery` | `ire/sandbox/recovery/terraform.tfstate` |

The retired monolithic Sandbox and Foundation roots are preserved in Git
history, not in the active directory tree. Existing AWS resource names that
contain the historical word `foundation` remain unchanged to prevent cosmetic
replacement.

## Configuration rules

- Keep reusable modules free of environment values.
- Keep secrets, account IDs, role ARNs, private keys and enterprise-only values
  outside this public configuration.
- Keep logical Terraform map keys stable; use display-name overrides when an
  AWS-visible name must differ.
- Do not move a resource between lifecycle roots as a readability change.
- Do not add a second tfvars file that assigns the same top-level variable.
- AAP/AWX is the supported full-IRE deployment path.

## Validation boundary

Static validation uses the four lifecycle roots with backends disabled. It does
not prove the selected account, backend key, permissions, quotas or runtime
network behavior. Those checks require the approved AAP plan workflow.
