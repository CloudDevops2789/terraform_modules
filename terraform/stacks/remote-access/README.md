# Remote Access stack

This lifecycle stack owns AWS Client VPN independently of Platform and Identity lifecycle ownership.

Platform networking is always required. AWS Managed Microsoft AD is required only for directory-based authentication modes.

## Contracts

AAP reads these outputs from approved upstream Terraform states:

- `platform_contract`: VPCs, association subnet IDs/CIDRs and target security
  groups;
- `identity_contract`: directory ID, DNS addresses and directory status when directory authentication is used.

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

When enabled, AAP brokers the server certificate ARN into the Remote Access lifecycle contract:

    server_certificate_arn: "<ACM_SERVER_CERTIFICATE_ARN>"

For directory authentication, AAP also brokers the Managed AD directory ID and
the bootstrap-generated authorization-group SID into the Remote Access
Terraform contract.

`authentication_type = "directory"` requires an ACM server certificate for TLS
termination, but it does not require a client certificate or client root CA.
End users authenticate with their directory credentials.

Mutual and directory-and-mutual authentication additionally require:

    client_root_certificate_chain_arn: "<ACM_CLIENT_ROOT_CERTIFICATE_CHAIN_ARN>"

Terraform consumes these identifiers but does not generate certificate material.

Server-certificate lifecycle operations are performed by dedicated AAP automation. The EasyRSA CA state is persisted independently through the Persistent stack using a private versioned S3 bucket protected by KMS.

AAP restores the existing EasyRSA PKI into a temporary workspace, generates the server certificate, imports it into ACM, removes the generated server private key from the PKI copy before persistence, and writes the updated PKI state back to KMS-encrypted S3.

Creation of a new EasyRSA CA is disabled by default and requires an explicit first-time bootstrap override.

The current EasyRSA provisioning workflow publishes its imported ACM certificate ARN as `server_certificate_arn` and, for mutual modes, as `client_root_certificate_chain_arn`. This is specific to the current EasyRSA implementation rather than a generic Client VPN module requirement.

## Client certificate issuance

Client certificate issuance uses the existing EasyRSA CA and is not allowed to create a new CA.

The client private key is generated and retained on the client device. AAP receives only the PEM certificate signing request (CSR).

AAP validates the CSR, restores the existing EasyRSA PKI, signs the CSR, persists the updated EasyRSA certificate database, and stores the signed client certificate and CA certificate in the protected PKI S3 bucket.

AAP never generates or receives the client private key.

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

## Mutual authentication

`authentication_type = "mutual"` requires Platform networking, an ACM server certificate, the approved client root certificate-chain ARN, and a valid client certificate/private-key pair. Managed AD is not required.

The IRE Remote Access stack maps `mutual` to the reusable Client VPN module `certificate` authentication mode.

## Directory and mutual authentication

`authentication_type = "directory_and_mutual"` requires both valid Managed AD credentials and a valid client certificate issued by the trusted certificate authority.

Both authentication methods must succeed.

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
