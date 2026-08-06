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

There is no direct Recovery Access-to-Protected Data route. The restriction is
enforced by VPC routes and Transit Gateway propagation.

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

The VPC module creates VPC-local resources and no routes. Current TGW routes
are declared in `routing.tf`.

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

## Firewall evolution

For distributed inspection, add the two reserved Core firewall subnets and
redirect selected routes in `routing.tf` to firewall endpoint IDs.

For centralized inspection, instantiate the same VPC module for
`10.213.255.0/24` and update TGW/routing composition.

Neither decision requires redesigning the reusable VPC module.

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

This foundation commit does not yet steer traffic through the Inspection VPC.
It creates no Network Firewall, Internet Gateway, NAT Gateway, default route,
or firewall endpoint route. Traffic steering will be introduced separately
after the firewall policy, firewall endpoints, and same-AZ return paths have
been validated together.

## Centralized Network Firewall

The centralized Inspection VPC contains a two-Availability-Zone AWS Network
Firewall deployment.

The initial strict-order policy permits only these VPC trust relationships:

```text
Recovery Access <-> Core Recovery <-> Protected Data
```

There is no rule permitting direct Recovery Access-to-Protected Data traffic.
Unmatched stateful traffic is dropped and alerted.

This stage creates the rule group, firewall policy, and firewall endpoints
only. No existing VPC or Transit Gateway route points to the firewall yet, so
current Sandbox traffic paths remain unchanged.

TLS traffic analysis is enabled for metadata visibility, but TLS decryption is
not configured. TLS inspection requires an organization-approved certificate
and trust-distribution process and will not be enabled using test PKI.
