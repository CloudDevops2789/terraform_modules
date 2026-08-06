# Sandbox Environment

## Account CIDR allocation

| CIDR | Purpose |
|---|---|
| `10.213.252.0/24` | Recovery Access VPC |
| `10.213.253.0/24` | Core Recovery VPC |
| `10.213.254.0/24` | Protected Data VPC |
| `10.213.255.0/24` | Centralized Inspection VPC |

## Trust path

```text
Recovery Access <-> Core Recovery <-> Protected Data
```

There is no direct Recovery Access-to-Protected Data route. Approved adjacent-tier
traffic is steered through the centralized Inspection VPC and AWS Network Firewall.

## Subnet groups

Recovery Access:

- `client-vpn`
- `admin-tools`
- `endpoints`
- `transit-gateway`

Core Recovery:

- `recovery-services`
- `directory-services`
- `endpoints`
- `transit-gateway`

`10.213.253.224/28` and `10.213.253.240/28` are reserved for distributed
Network Firewall endpoints if that option is selected.

Protected Data:

- `protected-workloads`
- `ingestion`
- `database`
- `file-services`
- `endpoints`
- `transit-gateway`

## Routing ownership

The VPC module creates VPC-local resources and no routes. `routing.tf` uses the
reusable `network-firewall-routing` module for all standalone VPC and Transit
Gateway static routes.

The Transit Gateway module remains the only owner of attachment associations
and route propagation.

No VPC creates an Internet Gateway or NAT Gateway.

## Local configuration

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
```

## Validation

```bash
terraform init -input=false -reconfigure -backend-config=backend.hcl
terraform fmt -check -recursive
terraform validate
terraform plan -input=false -var-file=terraform.tfvars -out=tfplan
```

Confirm the plan has no IGW, NAT Gateway, or direct Recovery Access-to-
Protected Data route.

## Firewall architecture

The selected design is centralized inspection using the dedicated
`10.213.255.0/24` Inspection VPC. The previously reserved Core Recovery CIDRs
remain unused and are not part of the active firewall path.

The reusable VPC, Transit Gateway, Network Firewall, logging, and routing
modules remain independently reusable.

## Centralized Inspection VPC foundation

The Sandbox now includes a dedicated centralized Inspection VPC using
`10.213.255.0/24`.

Its initial subnet allocation is:

| Subnet key | CIDR | Availability Zone index | Purpose |
|---|---|---:|---|
| `firewall-a` | `10.213.255.0/28` | 0 | Network Firewall endpoint |
| `firewall-b` | `10.213.255.16/28` | 1 | Network Firewall endpoint |
| `transit-gateway-a` | `10.213.255.32/28` | 0 | TGW VPC attachment |
| `transit-gateway-b` | `10.213.255.48/28` | 1 | TGW VPC attachment |

The Inspection VPC attachment enables Transit Gateway appliance mode.

The Inspection VPC contains the active centralized firewall path. It still
creates no Internet Gateway, NAT Gateway, public subnet, or internet default
route.

## Centralized Network Firewall

The centralized Inspection VPC contains a two-Availability-Zone AWS Network
Firewall deployment.

The initial strict-order policy permits only these VPC trust relationships:

```text
Recovery Access <-> Core Recovery <-> Protected Data
```

There is no rule permitting direct Recovery Access-to-Protected Data traffic.
Unmatched stateful traffic is dropped and alerted.

The rule group, firewall policy, and two firewall endpoints are integrated
with Transit Gateway routing. Approved inter-VPC traffic is inspected in both
directions.

TLS traffic analysis is enabled for metadata visibility, but TLS decryption is
not configured. TLS inspection requires an organization-approved certificate
and trust-distribution process and will not be enabled using test PKI.

## Encrypted Network Firewall logging

The Sandbox sends Network Firewall `ALERT` and `FLOW` records to separate
CloudWatch log groups:

| Log type | CloudWatch log group |
|---|---|
| `ALERT` | `/aws/network-firewall/ire-sandbox-centralized-inspection/alert` |
| `FLOW` | `/aws/network-firewall/ire-sandbox-centralized-inspection/flow` |

Both log groups:

- retain data for 30 days;
- use a dedicated customer-managed KMS key;
- restrict KMS service access through the CloudWatch Logs regional service
  principal and the `kms:EncryptionContext:aws:logs:arn` condition;
- remain separate from the general-purpose Sandbox KMS key.

TLS logging is not enabled because TLS decryption is not configured. The
detailed Network Firewall monitoring dashboard also remains disabled during
infrastructure validation to avoid automatic CloudWatch Logs Insights query
costs.

Logging remains independent of routing lifecycle and records traffic processed
by the stateful inspection engine.

## Centralized traffic steering

The final routing path is:

```text
Source spoke subnet
  -> Transit Gateway
  -> spoke TGW route table
  -> Inspection VPC attachment
  -> same-AZ Network Firewall endpoint
  -> Inspection TGW route table
  -> destination spoke attachment
  -> destination subnet
```

The return path follows the same firewall endpoint and Availability Zone
because appliance mode is enabled on the Inspection VPC attachment.

Transit Gateway behavior:

| Associated TGW route table | Approved static destination | Next hop |
|---|---|---|
| Recovery Access | Core Recovery | Inspection attachment |
| Core Recovery | Recovery Access | Inspection attachment |
| Core Recovery | Protected Data | Inspection attachment |
| Protected Data | Core Recovery | Inspection attachment |

The Inspection TGW route table learns all three spoke CIDRs through
propagation. The spoke route tables do not learn one another directly.

Inside the Inspection VPC, each TGW attachment subnet routes all three spoke
CIDRs to its same-AZ firewall endpoint, and each firewall subnet routes those
CIDRs back to Transit Gateway.

Recovery Access and Protected Data have no direct VPC route, no direct TGW
static route, and no firewall pass rule.

## Portable environment inputs

Environment-specific network allocations are supplied through `network_config`
in the selected `.tfvars` file. Standard resource names are derived from the
`naming` object, while `resource_name_overrides` supports exact organization-
approved names without changing Terraform resource addresses or logical keys.

Terraform logical keys, trust relationships, routing intent, Network Firewall
actions, and Suricata SIDs remain reviewed code. The security-policy value
`0.0.0.0/0` is intentionally not treated as an environment address allocation.

Backend configuration remains separate and must be paired with the matching
variable file for each environment.
