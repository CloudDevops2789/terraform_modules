# Remote Access stack

This lifecycle stack creates AWS Client VPN only after Platform networking and
AWS Managed Microsoft AD exist.

## Contracts

AAP reads these outputs from approved upstream Terraform states:

- `platform_contract`: VPCs, association subnet IDs/CIDRs and target security
  groups;
- `identity_contract`: directory ID, DNS addresses and directory status.

Operators cannot replace either contract through `terraform_variables`.

## Managed AD authorization binding

For directory-based authentication, the preceding Managed AD bootstrap workflow
publishes the authorization-group SID as:

```yaml
managed_ad_group_sid: S-1-5-21-...
```

AAP maps that workflow artifact internally to the Terraform
`client_vpn_access_group_id` variable. Operators do not copy or maintain the SID
in Job Template variables.

## Runtime bindings

When enabled, AAP supplies:

```yaml
terraform_variables:
  server_certificate_arn: "<ACM_SERVER_CERTIFICATE_ARN>"
```

For directory authentication, AAP also brokers the Managed AD directory ID and
the bootstrap-generated authorization-group SID into the Remote Access
Terraform contract.

`authentication_type = "directory"` requires an ACM server certificate for TLS
termination, but it does not require a client certificate or client root CA.
End users authenticate with their directory credentials.

Combined directory-and-mutual authentication additionally supplies:

```yaml
  client_root_certificate_chain_arn: "<ACM_CLIENT_ROOT_CA_ARN>"
```

Terraform consumes these identifiers and never generates, imports or stores
certificate private keys.

## Validated directory-authentication flow

The directory-authentication path has been validated end to end with:

- AWS Managed Microsoft AD provisioned before Remote Access;
- the VPN authorization group and test principal bootstrapped through AAP;
- the authorization-group SID passed through the runtime contract;
- AWS Client VPN created with `directory-service-authentication`;
- the target-network association reaching `associated`;
- a directory user successfully connecting with AWS VPN Client; and
- Remote Access and temporary validation resources successfully destroyed
  afterward.

The validation identifiers, credentials, account details, VPC IDs, directory
IDs, and certificate ARNs are intentionally not stored in this repository.

## Security-group source

AWS applies IPv4 SNAT to Client VPN traffic. Workload ingress is therefore
created from the exact Platform association-subnet CIDRs selected by
`network_binding`, not from `client_cidr_block` and not from the entire VPC by
default.

The endpoint security group automatically permits TCP and UDP port 53 only to
the DNS server addresses selected by `dns_configuration`. Other endpoint
egress and target ingress remain explicit environment policy.

## State

Backend key:

```text
ire/<environment>/remote-access/terraform.tfstate
```

See ADR-006 before moving an existing Client VPN endpoint from Platform state.
