# AWS Client VPN in the IRE network

AWS Client VPN provides controlled administrative access into the Recovery Access VPC.

It is an optional Remote Access capability and does not create direct trust between the recovery environment and production networks.

## Termination point

Client VPN target-network associations are created in dedicated Recovery Access subnets.

Administrator -> AWS Client VPN -> Recovery Access VPC

Access beyond Recovery Access remains subject to the IRE Transit Gateway, routing, Network Firewall, and workload security-group policies.

The existence of Client VPN does not create a direct Recovery Access-to-Protected Data path.

## Authentication

The IRE supports three Client VPN authentication modes:

- `directory`
- `mutual`
- `directory_and_mutual`

No federated or SAML Client VPN authentication mode is part of the IRE design.

### Directory

Directory authentication uses AWS Managed Microsoft AD credentials.

It requires Platform networking, the Identity contract, an approved AD authorization-group SID, and the Client VPN server certificate.

### Mutual

Mutual authentication uses a client certificate and its endpoint-local private key.

Managed AD is not required for this mode.

### Directory and mutual

`directory_and_mutual` requires both valid Managed AD credentials and a valid client certificate.

Both authentication methods must succeed.

## Certificate authority and client certificate lifecycle

The EasyRSA certificate authority is operationally managed through AAP and persisted outside the execution environment.

Persistent stack resources provide:

- a private versioned S3 bucket for EasyRSA PKI state
- a KMS key used for server-side encryption of that PKI archive

AAP restores the existing PKI into a temporary workspace when certificate operations are required.

Creation of a new EasyRSA CA is disabled by default and must be explicitly allowed only for first-time bootstrap.

Client certificate issuance always requires an existing CA and is not permitted to create a replacement CA.

The client private key is generated and retained on the client device. Only the CSR is supplied to AAP for signing.

## Routing and authorization

Client VPN routing and authorization are separate controls.

A route determines whether the Client VPN endpoint has a forwarding path to a destination.

An authorization rule determines whether an authenticated client is permitted to use that destination.

Only explicitly approved destination networks should be authorized.

The IRE does not use Client VPN as an unrestricted extension into Protected Data.

## Source NAT and security-group policy

AWS Client VPN applies IPv4 source NAT to client traffic.

Target workloads therefore see the Client VPN network-interface address from an associated subnet rather than the original Client VPN client-pool address.

Security-group rules must use the approved association-subnet CIDRs where network-source rules are required.

They must not assume that `client_cidr_block` is visible as the source address on the target workload.

## DNS

Directory-based authentication uses DNS addresses supplied by the Identity contract.

Remote Access permits only the DNS traffic required to those selected directory DNS addresses.

## Connection logging

Client VPN connection logging is sent to CloudWatch Logs when enabled.

Creating the log group and stream does not by itself prove that connection events are being delivered.

Operational validation must confirm successful log delivery in the deployed environment.

## Ownership

Persistent owns durable Client VPN PKI S3 and KMS resources.

Platform owns the Recovery Access VPC, Client VPN association subnets, shared routing, and workload security groups.

Identity owns AWS Managed Microsoft AD and directory DNS.

Remote Access owns the Client VPN endpoint, target-network associations, authorization rules, routes, endpoint security group, additive workload ingress, and connection logging.

AAP performs server-certificate lifecycle operations, client CSR signing, and lifecycle contract brokering.
