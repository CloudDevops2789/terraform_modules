# Route 53 Resolver Module

## Purpose

This module creates one private Route 53 Resolver endpoint and optionally creates:

- outbound DNS forwarding rules;
- rule associations with caller-selected VPCs; and
- associations with an existing Resolver query-log configuration.

It does not create public or private hosted zones, VPCs, subnets, security groups,
network routes, log destinations, or KMS keys.

## Design boundary

The caller controls all architecture through explicit inputs:

- endpoint direction;
- endpoint name and IP family;
- private subnet IDs;
- security-group IDs;
- DNS suffixes and target resolver IPs;
- associated VPC IDs; and
- an optional existing query-log configuration.

No domain, VPC role, CIDR, Region, account, or organization-specific value is
embedded in the reusable module.

## Example: private forwarding to directory DNS

```hcl
module "private_dns" {
  source = "../../modules/route53-resolver"

  name               = "example-private-dns"
  direction          = "OUTBOUND"
  subnet_ids         = local.resolver_subnet_ids
  security_group_ids = [local.resolver_security_group_id]

  forwarding_rules = {
    directory = {
      domain_name = "ad.example.internal"
      target_ips = [
        { ip = "10.20.1.10" },
        { ip = "10.20.2.10" }
      ]
      vpc_ids = local.approved_client_vpc_ids
    }
  }

  tags = local.tags
}
```

The associated VPCs continue using AmazonProvidedDNS. Only names matching the
configured suffix are forwarded through the outbound endpoint.

## Security requirements

- Place endpoint ENIs in private subnets across at least two Availability Zones.
- For outbound endpoints, allow only required DNS egress to approved target resolvers.
- Authorize corresponding TCP and UDP port 53 ingress on the target resolvers.
- Do not create a catch-all `.` rule without architecture and security approval.
- Supply a pre-existing query-log configuration when DNS query logging is required.
- Review routing to every target resolver before deployment.

## Lifecycle considerations

Changing endpoint direction, subnet placement, or endpoint IP family can replace
the endpoint. Review Terraform plans for replacement before apply. Resolver
endpoints incur hourly charges for their endpoint IP addresses, so consumers
should enable them only for an approved DNS requirement.
