# Sandbox Environment

The Sandbox is the integrated Terraform root for the AWS Isolated Recovery
Environment. It composes four VPCs, Transit Gateway segmentation, centralized
AWS Network Firewall inspection, administrative Client VPN access, security
groups, representative EC2 resources, KMS, and AWS Backup modules.

> **Current status:** formatted, validated, and planned successfully. No
> Terraform apply was performed during the current implementation work.

## Portable inputs

Environment-specific values are defined in the selected `.tfvars` file:

- `network_config` contains the account allocation, VPC CIDRs, subnet CIDRs,
  Client VPN CIDR, and future hybrid network ranges.
- `naming` supplies standard naming components.
- `resource_name_overrides` permits exact organization-approved names without
  changing Terraform logical keys.
- `org_*` variables supply mandatory enterprise tags.

`terraform.tfvars.example` is shareable. `terraform.tfvars` is local and ignored.

The example file currently demonstrates the approved Sandbox allocation:

| Logical network | Example CIDR |
|---|---|
| Account allocation | `10.213.252.0/22` |
| Recovery Access | `10.213.252.0/24` |
| Core Recovery | `10.213.253.0/24` |
| Protected Data | `10.213.254.0/24` |
| Centralized Inspection | `10.213.255.0/24` |
| Client VPN clients | `192.168.0.0/16` |

These are input values, not hardcoded reusable-module assumptions.

## Four-VPC topology

### Recovery Access

Subnet groups:

- `client-vpn`
- `admin-tools`
- `endpoints`
- `transit-gateway`

Client VPN associates only with the `client-vpn` subnets. Administrators reach
approved management hosts in the `admin-tools` subnets.

### Core Recovery

Subnet groups:

- `recovery-services`
- `directory-services`
- `endpoints`
- `transit-gateway`

Core Recovery hosts recovery tooling and the administrative control plane.

### Protected Data

Subnet groups:

- `protected-workloads`
- `ingestion`
- `database`
- `file-services`
- `endpoints`
- `transit-gateway`

Protected Data has no direct route from Recovery Access or Client VPN.

### Centralized Inspection

Subnet groups:

- `network-firewall`
- `transit-gateway`

Two firewall subnets and two Transit Gateway attachment subnets are distributed
across two Availability Zones. The Inspection attachment enables appliance mode.

The Inspection VPC has no Internet Gateway, NAT Gateway, public subnet, or
internet default route.

## Approved traffic model

| Flow | Treatment |
|---|---|
| Recovery Access ↔ Core Recovery | Inspected centrally |
| Core Recovery ↔ Protected Data | Inspected centrally |
| Recovery Access ↔ Protected Data | No route |
| Client VPN → Recovery Access admin host | Local Recovery Access path; no firewall hairpin |
| Admin host → Core Recovery | Inspected centrally |
| Site-to-Site VPN → Core Recovery | Planned; must traverse inspection |
| Site-to-Site VPN → Protected Data | No general route |
| Intra-VPC traffic | Security groups and workload controls |

## Centralized inspection path

```text
Source spoke subnet
  → source VPC route table
  → Transit Gateway
  → source TGW route table
  → Inspection VPC attachment
  → same-AZ Network Firewall endpoint
  → Inspection TGW route table
  → destination attachment
  → destination VPC route table
  → destination subnet
```

The return path uses the same Availability Zone and firewall endpoint.

### Transit Gateway policy

- Default route-table association is disabled.
- Default route propagation is disabled.
- Spoke attachments propagate only into the Inspection TGW route table.
- Spoke TGW route tables contain explicit static routes to the Inspection
  attachment.
- The Inspection TGW route table learns the three spoke CIDRs.
- Recovery Access and Protected Data never learn or receive a direct route to
  one another.

## Network Firewall policy

The Sandbox deploys:

- one centralized two-AZ firewall;
- one strict-order stateful segmentation rule group;
- one strict-order firewall policy;
- stateless forwarding to the stateful engine;
- default strict drop and alert actions;
- metadata analysis for HTTP host and TLS SNI;
- no TLS decryption.

The approved stateful trust relationships are:

```text
Recovery Access ↔ Core Recovery ↔ Protected Data
```

Security groups continue to enforce workload-level protocols and ports.

## Encrypted logging

Network Firewall sends separate `ALERT` and `FLOW` logs to CloudWatch Logs.

The log-group names are derived from portable naming inputs. Both log groups:

- retain data for 30 days in the current example;
- use a dedicated customer-managed KMS key;
- use the regional CloudWatch Logs service principal;
- restrict KMS use with the log-group encryption context;
- remain separate from the general Sandbox KMS key.

TLS logging is disabled because TLS decryption is not configured.

## Client VPN boundary

Client VPN terminates in Recovery Access. The Sandbox currently defines:

- mutual certificate authentication;
- target-network associations in Recovery Access;
- authorization only for the Recovery Access CIDR;
- no explicit Client VPN route to Core Recovery;
- no Client VPN route to Protected Data.

The intended administrative flow is:

```text
Administrator
  → Client VPN
  → Recovery Access admin host
  → centralized inspection
  → Core Recovery
```

## Routing ownership

- `module.vpc` creates VPC-local networking resources and no routes.
- `module.transit_gateway` creates TGW attachments, TGW route tables,
  associations, and propagation.
- `module.network_firewall_routing` creates standalone VPC routes and static TGW
  routes.
- The environment owns topology, security intent, and route composition.

## Local setup

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
```

Do not commit either local file.

## Initialize, validate, and plan

```bash
terraform init \
  -input=false \
  -reconfigure \
  -backend-config=backend.hcl

terraform fmt -check -recursive
terraform validate

terraform plan \
  -input=false \
  -var-file=terraform.tfvars \
  -out=tfplan
```

Current empty-state expectation:

```text
Plan: 187 to add, 0 to change, 0 to destroy.
```

Review and remove the plan:

```bash
terraform show tfplan
rm -f tfplan
```

No Sandbox apply is part of the current validation workflow.

## Required plan checks

Confirm that the plan contains:

- four VPCs;
- no Internet Gateway or NAT Gateway;
- no IPv4 or IPv6 default route;
- four TGW VPC attachments;
- four TGW route-table associations;
- three TGW route propagations;
- four static spoke TGW routes to the Inspection attachment;
- one Network Firewall, policy, and stateful rule group;
- same-AZ endpoint routing;
- encrypted `ALERT` and `FLOW` logging;
- no direct Recovery Access-to-Protected Data route.

## Implemented versus planned

Implemented in Terraform:

- four-VPC topology;
- centralized Network Firewall;
- inspected adjacent-zone paths;
- encrypted firewall logging;
- Recovery Access Client VPN;
- security groups;
- representative EC2 resources;
- KMS and AWS Backup composition;
- portable network and naming inputs.

Planned, not implemented:

- Site-to-Site VPN and hybrid TGW route table;
- runtime packet-flow and failover testing;
- narrowly scoped on-premises ingestion exception, if approved;
- production PKI-backed TLS decryption;
- production lifecycle protection settings.
