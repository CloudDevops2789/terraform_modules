# ADR-003: Private DNS and Route 53 Resolver Strategy

## Status

Accepted; revised to cover multi-VPC Managed Microsoft AD resolution.

## Context

AWS Managed Microsoft AD is authoritative for its own directory DNS namespace.
Creating a Route 53 private hosted zone for the same namespace would introduce
competing authority and could prevent clients from discovering the directory's
LDAP and Kerberos service records.

IRE workloads should normally continue using AmazonProvidedDNS because AWS
interface endpoint private DNS and AWS internal names depend on it. Workloads in
other VPCs nevertheless need a private mechanism to resolve the directory
namespace without replacing their primary resolver configuration.

Route 53 Resolver endpoints have directional names that describe query flow:

- an outbound endpoint forwards selected queries from VPC Resolver to a target
  DNS service in another network location, including another VPC; and
- an inbound endpoint accepts DNS queries from an on-premises network or another
  connected network and passes them to VPC Resolver.

`OUTBOUND` does not inherently mean internet or external DNS. A forwarding rule
can target private AWS Managed AD DNS addresses inside the IRE.

## Decision

Provide a reusable `route53-resolver` module supporting:

- private inbound or outbound endpoint placement;
- caller-supplied subnet and security-group IDs;
- explicit outbound forwarding rules and target DNS IP addresses;
- rule associations with caller-selected VPCs; and
- optional association with an existing Resolver query-log configuration.

The reusable module creates no VPCs, hosted zones, security groups, routes, log
destinations, KMS keys, public records, or internet connectivity.

The Identity stack optionally composes an outbound endpoint for its managed
directory. When enabled, it:

1. places endpoint ENIs in a caller-selected private subnet group;
2. forwards only the managed directory FQDN to the directory DNS addresses;
3. associates the rule only with caller-approved VPCs; and
4. permits only TCP and UDP port 53 between the endpoint security group and the
   AWS-managed directory security group.

The capability remains disabled by default. Environment configuration must make
the deployment and VPC associations explicit.

No private hosted zone is created for the directory namespace. Managed Microsoft
AD remains authoritative for that namespace.

## Hybrid DNS boundary

On-premises DNS integration is a separate decision. Until private connectivity,
source networks, DNS namespaces and operational ownership are approved:

- do not create an inbound Resolver endpoint;
- do not forward on-premises or production namespaces;
- do not configure a catch-all `.` forwarding rule; and
- do not establish DNS behavior that implies an Active Directory trust.

When hybrid DNS is approved, the same reusable module can create the required
endpoint. Its rules and associations must remain environment configuration.

## Consequences

- AWS workloads retain AmazonProvidedDNS for AWS private service names.
- Only the directory suffix is sent to Managed AD DNS.
- Resolver endpoint IP addresses incur hourly and query-processing charges when
  the capability is enabled.
- Endpoint direction, subnet placement, and IP-family changes can cause
  replacement and require explicit plan review.
- DNS reachability does not grant directory trust or application access; TGW,
  route-table, security-group and directory controls remain authoritative.

## Related

- ADR-002: Managed AD placement and lifecycle
- ADR-004: Recovery artifact repository and external-reachability boundary
- ADR-005: Separation between clean administrative AD and restored AD
