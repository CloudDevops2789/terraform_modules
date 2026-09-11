# ADR-003: IRE DNS Authority and Resolution Strategy

- **Status:** Accepted
- **Date:** 2026-08-27
- **Scope:** Customer-neutral IRE reference architecture

## Context

The IRE will contain two separate Active Directory environments:

1. A clean AWS Managed Microsoft AD domain named `ad.ire.example` for administering the IRE.
2. A restored copy of the on-premises `corp.example` domain for recovered applications and workloads.

Each Active Directory environment includes Microsoft DNS and owns the DNS records for its domain. Recovered workloads must authenticate against the restored `corp.example` domain. IRE administrators must continue to use the clean AWS Managed AD domain.

Route 53 Resolver is required to direct DNS queries to the correct DNS authority. Route 53 does not authenticate users or replace Active Directory DNS.

## Decision

The IRE will use the following DNS ownership model:

| Namespace | DNS authority | Purpose |
|---|---|---|
| `ad.ire.example` | AWS Managed AD DNS | Clean IRE administration |
| `corp.example` | Restored production AD DNS | Recovered workloads and applications |
| A future AWS-only namespace | Route 53 private hosted zone, if approved | AWS-native services that should not depend on either AD |

Route 53 Resolver will send queries to the correct DNS authority by using domain-specific forwarding rules.

```mermaid
flowchart TD
    Q["DNS query from an IRE system"] --> R["Route 53 Resolver"]
    R -->|"ad.ire.example"| C["Clean AWS Managed AD DNS"]
    R -->|"corp.example"| P["Restored production AD DNS"]
```

## How authentication works

Route 53 Resolver only helps a workload find the correct domain controller.

For a recovered workload:

1. The workload asks DNS for a `corp.example` domain controller.
2. Route 53 Resolver forwards the query to the restored production DNS servers.
3. Restored production DNS returns the domain-controller address.
4. The workload connects directly to the restored domain controller for Kerberos, LDAP, Group Policy and authentication.

## Resolver rules

The target design contains two forwarding rules:

| Resolver rule | Forwarding target | Association |
|---|---|---|
| `ad.ire.example` | AWS Managed AD DNS IP addresses | Only VPCs requiring clean IRE directory resolution |
| `corp.example` | Restored production DC DNS IP addresses | Initially the Protected Data VPC only |

The `corp.example` rule will be created only after the restored domain controllers exist and their private DNS IP addresses are known.

## Private hosted zone decision

No Route 53 private hosted zone will be created for either Active Directory domain.

- `ad.ire.example` is already owned by AWS Managed AD DNS.
- `corp.example` is already owned by the restored production AD DNS.
- Creating Route 53 hosted zones with either name would duplicate DNS authority and complicate operations.

A private hosted zone is optional, not mandatory. It will be introduced only if the customer approves a separate AWS-owned namespace for services that should be managed through AWS and Terraform independently of Active Directory.

Records beneath an existing AD namespace may continue to be created in that domain's Microsoft DNS. For example, an IRE management record beneath `ad.ire.example` may be managed by AWS Managed AD DNS; it does not require a private hosted zone.

## Security and isolation

- No trust relationship is assumed between the clean AWS Managed AD and the restored `corp.example` domain.
- The restored domain is treated as untrusted until cyber-recovery validation is complete.
- DNS resolution of `corp.example` will be limited initially to recovered workloads in the Protected Data VPC.
- The restored domain controllers must be prevented from reconnecting to or replicating with production domain controllers during an isolated recovery.
- Core Recovery, Recovery Access and Inspection will not receive `corp.example` resolution unless a documented operational requirement is approved.

## Terraform ownership

- The reusable Route 53 Resolver endpoint and rule capability remains customer-neutral.
- Customer-specific domain names, DNS targets and VPC associations remain only in the customer-specific configuration branches.
- The clean Managed AD forwarding rule belongs to the Identity lifecycle.
- The future `corp.example` forwarding rule belongs to the Recovery lifecycle because it depends on restored domain-controller addresses.
- The existing outbound Resolver endpoint should be reused where lifecycle and isolation requirements permit. A second endpoint will not be created without a documented reason.

## Consequences

### Benefits

- Clear ownership for every DNS namespace.
- Recovered workloads can locate and authenticate against restored production AD.
- IRE administrators remain on a separate clean directory.
- AWS service-name resolution remains available through the VPC Resolver.
- No unnecessary private hosted zone or duplicate DNS records are introduced.

### Trade-offs

- Recovery automation must publish the restored DC DNS addresses before enabling the `corp.example` forwarding rule.
- DNS and authentication must be validated before application recovery begins.
- Any future cross-domain access requires a separate security decision and is not implied by this ADR.

## Not decided by this ADR

- A trust relationship between the two directories.
- The name of a future AWS-only private namespace.
- Reconnection of the restored domain to production.
- Public DNS or internet-facing records.
