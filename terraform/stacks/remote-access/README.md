# Remote Access stack

This lifecycle stack creates AWS Client VPN only after Platform networking and
AWS Managed Microsoft AD exist.

## Contracts

AAP reads these outputs from approved upstream Terraform states:

- `platform_contract`: VPCs, association subnet IDs/CIDRs and target security
  groups;
- `identity_contract`: directory ID, DNS addresses and directory status.

Operators cannot replace either contract through `terraform_variables`.

## Runtime bindings

When enabled, AAP supplies:

```yaml
terraform_variables:
  client_vpn_access_group_id: "<MANAGED_AD_GROUP_SID>"
  server_certificate_arn: "<ACM_SERVER_CERTIFICATE_ARN>"
```

Future combined authentication additionally supplies:

```yaml
  client_root_certificate_chain_arn: "<ACM_CLIENT_ROOT_CA_ARN>"
```

Terraform consumes these identifiers and never generates, imports or stores
certificate private keys.

## Security-group source

AWS applies IPv4 SNAT to Client VPN traffic. Workload ingress is therefore
created from the exact Platform association-subnet CIDRs selected by
`network_binding`, not from `client_cidr_block` and not from the entire VPC by
default.

## State

Backend key:

```text
ire/<environment>/remote-access/terraform.tfstate
```

See ADR-006 before moving an existing Client VPN endpoint from Platform state.
