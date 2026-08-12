# Terraform Configuration Reference

This document explains the major root inputs used by the integrated IRE Terraform environment and how they map to architecture intent.

The current environment root is:

```text
terraform/environments/sandbox
```

The directory name is an implementation path. The configuration model is intended to remain portable across approved IRE environments.

## Configuration flow

```text
Environment configuration
        ↓
Root variables
        ↓
Locals / normalization
        ↓
Environment module calls
        ↓
Reusable modules
        ↓
AWS resources
```

## Major variable groups

### `aws_region`

AWS Region in which the environment is composed.

Typical flow:

```text
aws_region
   ↓
AWS provider / environment modules
   ↓
Regional AWS resources
```

### `naming`

Provides portable naming components.

Current structure:

```text
naming
├── organization
├── project
├── project_display_name
├── environment
├── environment_display_name
├── region_code
└── suffix
```

Purpose:

- separate naming intent from reusable module implementation;
- derive consistent resource names;
- support optional environment/Region suffixing;
- reduce hard-coded resource names.

`resource_name_overrides` can provide exact approved names where derived naming is not sufficient.

### `network_config`

Defines the environment network allocation.

```text
network_config
├── account_cidr_block
├── client_vpn_cidr_block
└── vpcs
    ├── recovery_access
    ├── core_recovery
    ├── protected_data
    └── inspection
```

Each VPC contains:

- its VPC CIDR;
- named subnet CIDRs used by the environment composition.

#### Recovery Access

Subnet groups include:

- Client VPN;
- administrative tools;
- private endpoints;
- Transit Gateway attachments.

#### Core Recovery

Subnet groups include:

- recovery services;
- directory services;
- private endpoints;
- Transit Gateway attachments.

#### Protected Data

Subnet groups include:

- protected workloads;
- ingestion;
- databases;
- file services;
- private endpoints;
- Transit Gateway attachments.

#### Inspection

Subnet groups include:

- AWS Network Firewall endpoints;
- Transit Gateway attachments.

### `network_inspection_mode`

Controls the approved inter-VPC traffic treatment.

Supported values:

```text
firewall
bypass
```

`firewall` routes approved adjacent-zone traffic through centralized AWS Network Firewall inspection.

`bypass` retains the logical trust model but routes approved adjacent-zone traffic directly through Transit Gateway.

Neither mode should introduce a direct Recovery Access-to-Protected Data trust path.

### Client VPN variables

```text
authentication_type
server_certificate_arn
root_certificate_chain_arn
saml_provider_arn
manage_saml_provider
saml_provider_name
saml_metadata_document
```

#### Certificate mode

```text
authentication_type = certificate
server_certificate_arn = required
root_certificate_chain_arn = required
```

#### Federated mode

Federated authentication supports two IAM SAML provider ownership models.

Existing provider:

```text
authentication_type = federated
server_certificate_arn = required
manage_saml_provider = false
saml_provider_arn = required
```

Terraform-managed provider:

```text
authentication_type = federated
server_certificate_arn = required
manage_saml_provider = true
saml_provider_name = approved name
saml_metadata_document = supplied at runtime
```

The environment resolves the effective IAM SAML provider ARN before passing it to the Client VPN module.

MFA remains an enterprise identity-provider policy.

### `security_group_rules`

Logical security-group policy.

Rules use logical security-group and network-zone references so policy remains portable across environment-specific AWS IDs.

### `network_firewall_rules`

Ordered Network Firewall policy used by the integrated environment.

Security-group and Network Firewall policy are maintained in:

```text
terraform/environments/sandbox/network-policy.auto.tfvars
```

This allows trust-policy changes to remain code-reviewed.

### Organization metadata

Organization metadata is currently provided through `org_*` variables and applied through environment tagging logic.

The variable interface is intentionally separate from reusable module resource implementation.

### Sensitive values

Sensitive Terraform values should be injected through the approved runtime mechanism.

Examples include:

- directory-service passwords;
- secret material required by future integrations.

Secrets must not be stored in tracked `.tfvars` examples.

## Public-key handling

The current integrated Terraform environment consumes `public_key_path`.

Direct Terraform execution can supply a local public-key path.

AAP orchestration accepts public-key content, creates a temporary public-key file in the execution workspace, and injects the temporary path into Terraform.

Only public-key material is registered with AWS EC2 key-pair resources.

## Understanding a variable change

When reviewing a root variable, follow this sequence:

```text
1. Find variable declaration
2. Find all var.<name> references
3. Identify local transformations
4. Identify module input
5. Inspect reusable module variable
6. Inspect AWS resource field
7. Inspect resulting output
```

Example:

```text
network_config.vpcs.recovery_access
        ↓
environment composition
        ↓
VPC module input
        ↓
aws_vpc / aws_subnet resources
        ↓
VPC and subnet outputs
```

## Configuration design principles

The environment root should make architecture intent visible.

Reusable modules should:

- avoid environment-specific CIDRs;
- avoid organization-specific credentials;
- use typed interfaces;
- expose stable outputs;
- avoid hidden route creation unless routing is the module's explicit responsibility.

The environment root should:

- compose architecture-specific relationships;
- own environment-level routing decisions;
- provide approved naming and tagging inputs;
- keep trust policy reviewable;
- minimize unnecessary input transformations.

## Related documents

- [`module-map.md`](module-map.md)
- [`../aap/variables.md`](../aap/variables.md)
