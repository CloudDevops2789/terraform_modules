# Terraform Architecture-to-Code Map

This document maps the IRE architecture to the current Terraform repository structure.

## High-level map

```text
IRE architecture
│
├── Recovery Access VPC
│   ├── VPC module
│   ├── Client VPN module
│   ├── Security-group modules
│   └── Transit Gateway attachment
│
├── Core Recovery VPC
│   ├── VPC module
│   ├── Recovery-service subnets
│   ├── Directory-service subnets
│   ├── Security-group modules
│   └── Transit Gateway attachment
│
├── Protected Data VPC
│   ├── VPC module
│   ├── Workload / ingestion / database / file-service subnets
│   ├── Security-group modules
│   └── Transit Gateway attachment
│
├── Inspection VPC
│   ├── VPC module
│   ├── AWS Network Firewall
│   ├── Firewall policy
│   ├── Rule groups
│   ├── Logging
│   ├── Routing
│   └── Transit Gateway attachment
│
└── Recovery services
    ├── AWS Backup
    ├── KMS
    ├── EC2
    └── Directory-service module
```

## Environment root

The current integrated root is:

```text
terraform/environments/sandbox
```

The root composes reusable modules and contains architecture-specific relationships.

## Reusable modules

| Module | Primary responsibility |
|---|---|
| `vpc` | VPC, subnets, route tables, associations, optional IGW |
| `transit-gateway` | TGW, attachments, TGW route tables, associations, propagation |
| `client-vpn` | Client VPN endpoint, target associations, authorization, authentication configuration |
| `iam-saml-provider` | Optional AWS IAM SAML provider creation from approved metadata |
| `security-group` | Security-group resources |
| `security-group-rule` | Standalone ingress/egress rules |
| `network-firewall` | AWS Network Firewall resource |
| `network-firewall-policy` | Firewall policy |
| `network-firewall-rule-group` | Firewall rule groups |
| `network-firewall-routing` | Inspection-specific routing |
| `network-firewall-logging` | Network Firewall logging |
| `network-firewall-tls-inspection` | TLS inspection configuration |
| `kms` | Customer-managed KMS keys |
| `ec2` | EC2 instances |
| `key-pair` | EC2 public-key registration |
| `managed-microsoft-ad` | AWS Managed Microsoft AD |
| `backup-*` | Backup vaults, plans, copy actions, roles, and selections |

## Routing ownership

### VPC module

Owns:

- VPC;
- subnets;
- route tables;
- subnet-to-route-table associations;
- optional Internet Gateway.

The generic VPC module does not own arbitrary environment routes.

### Transit Gateway module

Owns:

- Transit Gateway;
- VPC attachments;
- TGW route tables;
- attachment associations;
- propagation.

### Network Firewall routing

Owns the standalone VPC and Transit Gateway route resources required for the centralized inspection pattern.

This keeps environment routing policy out of the generic VPC module.

## Architecture relationships

### Recovery Access → Core Recovery

```text
Recovery Access subnet
        ↓
Recovery Access route table
        ↓
Transit Gateway
        ↓
Inspection path when firewall mode is enabled
        ↓
Transit Gateway
        ↓
Core Recovery subnet
```

### Core Recovery → Protected Data

```text
Core Recovery subnet
        ↓
Core route table
        ↓
Transit Gateway
        ↓
Inspection path when firewall mode is enabled
        ↓
Transit Gateway
        ↓
Protected Data subnet
```

### Recovery Access → Protected Data

No direct trust path is intended.

Any future exception must be represented explicitly in routing and security policy.

## Policy ownership

```text
network-policy.auto.tfvars
        ↓
security_group_rules
network_firewall_rules
        ↓
environment policy transformation
        ↓
security-group / firewall modules
```

Policy is kept in version control so trust changes can be reviewed through Git.

## Client VPN flow

```text
authentication inputs
        ↓
environment Client VPN composition
        ↓
client-vpn module
        ↓
aws_ec2_client_vpn_endpoint
        ↓
target network associations
authorization rules
```

Authentication mode:

```text
certificate
    ├── server certificate
    └── root certificate chain

federated
    ├── server certificate
    └── IAM SAML provider
         ├── existing enterprise-managed provider
         └── optional Terraform-managed provider
```

## AAP-to-Terraform flow

```text
AAP runtime inputs
        ↓
terraform_deploy.yml
        ↓
AssumeRole
        ↓
temporary STS credentials
        ↓
temporary tfvars/public-key material
        ↓
terraform/environments/sandbox
        ↓
reusable modules
        ↓
AWS
```

## Review method

For each architecture component, review in this order:

```text
1. Environment root file
2. Root variable
3. Local transformation
4. Module call
5. Reusable module input
6. AWS resource
7. Module output
8. Environment output
```

This map is intentionally high level. It should be updated when the root environment composition or module ownership boundaries change.

## Related documents

- [`configuration-reference.md`](configuration-reference.md)
- [`../aap/README.md`](../aap/README.md)
