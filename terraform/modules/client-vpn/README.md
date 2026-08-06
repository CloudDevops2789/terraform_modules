# AWS Client VPN Terraform Module

Creates an AWS Client VPN endpoint with mutual-certificate authentication,
CloudWatch connection logging, target-network associations, authorization rules,
optional routes, and caller-supplied security groups.

The module is reusable and does not decide the caller's network trust model.

## Resources

- `aws_ec2_client_vpn_endpoint`
- `aws_ec2_client_vpn_network_association`
- `aws_ec2_client_vpn_authorization_rule`
- optional `aws_ec2_client_vpn_route`
- CloudWatch log group and stream when connection logging is enabled

## Required architecture inputs

| Input | Purpose |
|---|---|
| `name` | Endpoint display name |
| `client_cidr_block` | Address pool assigned to VPN clients |
| `server_certificate_arn` | ACM server certificate |
| `root_certificate_chain_arn` | Trusted client-certificate CA |
| `vpc_id` | VPC containing target-network association subnets |
| `network_associations` | Association subnet IDs keyed by logical name |
| `security_group_ids` | Security groups attached to Client VPN ENIs |

Optional inputs control authorization rules, routes, split tunnel, protocol,
port, DNS servers, session timeout, logging, retention, and tags.

## Outputs

- endpoint ID and ARN;
- DNS name;
- target-network association IDs;
- authorization rule IDs;
- route IDs;
- CloudWatch log-group name.

## Sandbox composition

The Sandbox terminates Client VPN in the Recovery Access VPC:

```hcl
module "client_vpn" {
  source = "../../modules/client-vpn"

  name = local.resource_names.client_vpn

  server_certificate_arn     = var.server_certificate_arn
  root_certificate_chain_arn = var.root_certificate_chain_arn

  client_cidr_block = local.client_vpn.client_cidr_block
  vpc_id            = module.recovery_access.vpc_id

  network_associations = {
    for key, subnet in module.recovery_access.subnets :
    key => {
      subnet_id = subnet.id
    }
    if subnet.group == "client-vpn"
  }

  security_group_ids = [
    module.security_group.security_group_ids["management"],
  ]

  authorization_rules = {
    recovery_access = {
      target_network_cidr  = module.recovery_access.vpc_cidr
      authorize_all_groups = local.client_vpn.authorize_all_groups
    }
  }

  routes = {}

  tags = local.org_tags
}
```

This is an environment decision, not a module restriction.

## Administrative traffic boundary

The approved Sandbox path is:

```text
Administrator
  → AWS Client VPN
  → Recovery Access admin host
  → Transit Gateway
  → centralized Network Firewall
  → Core Recovery
```

The Client VPN endpoint itself is not hairpinned through the centralized
firewall to reach an admin host in the same VPC.

The Sandbox does not define:

- a Client VPN route directly to Core Recovery;
- a Client VPN route to Protected Data;
- a Recovery Access-to-Protected Data route.

## Routes and authorization

Routes and authorization rules are separate controls:

- a route determines how the endpoint forwards to a destination;
- an authorization rule determines whether a client is allowed to use that
  destination.

AWS creates local reachability for the associated VPC. Do not duplicate that
associated-VPC route. Add explicit route resources only for approved remote
networks.

## Certificate boundary

The module consumes existing ACM certificate ARNs. Production certificate
issuance, private-key custody, rotation, revocation, and client trust
distribution remain outside this module.

## Security guidance

- Prefer organization-approved certificate and MFA processes.
- Associate only dedicated private subnets.
- Use split tunnel only with an explicit security decision.
- Restrict authorization to approved networks and groups.
- Attach narrowly scoped security groups.
- Enable connection logging.
- Do not treat Client VPN as a direct extension into Protected Data.
