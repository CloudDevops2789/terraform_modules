# Client VPN + Managed AD Proof Stack

This short-lived stack proves AWS Client VPN authentication against AWS Managed
Microsoft AD without deploying the four-VPC IRE Platform.

It creates:

- one isolated VPC;
- two private subnets in different Availability Zones;
- one Standard AWS Managed Microsoft AD directory;
- one private Windows Server 2022 EC2 validation instance;
- one operator-supplied EC2 key pair;
- one optional Client VPN endpoint and target-network association;
- narrowly scoped security groups and connection logging.

It creates no Internet Gateway, NAT Gateway, Transit Gateway, Network Firewall,
public IP address, Route 53 Resolver endpoint, or private hosted zone.

## Authentication stages

The directory must exist before its user/group can be bootstrapped. The Client
VPN authorization rule then consumes the group's SID.

1. Deploy with `client_vpn_enabled: false`.
2. Run `playbooks/client_vpn_ad_poc_bootstrap.yml` to create the test user and
   VPN access group and capture the group SID.
3. Deploy with `client_vpn_enabled: true`, `authentication_type: directory`,
   and the returned `client_vpn_access_group_id`.
4. Validate username/password authentication and private EC2 reachability.
5. Redeploy with `authentication_type: directory_and_mutual` and an approved
   root CA ARN to validate that both credentials and a client certificate are
   required.
6. Run the guarded POC destroy immediately after evidence is captured.

Authentication-mode changes replace the Client VPN endpoint. They do not
replace the VPC, directory, key pair, or EC2 test instance.

## Certificate boundary

The stack consumes existing ACM certificate ARNs supplied at runtime. It does
not issue or import server certificates, client certificates, or certificate
authorities, and it does not generate, store, export, or distribute private
keys. A server certificate ARN is required for both modes. Combined mode also
requires the ACM root CA certificate-chain ARN that validates the
operator-held client certificate.

## Identity bootstrap

The bootstrap playbook uses AWS Directory Service Data through the assumed AAP
role. It creates the configured group and user idempotently, sets the user's
password from the `IRE_CLIENT_VPN_TEST_USER_PASSWORD` credential environment,
adds the user to the group, and publishes the non-secret group SID.

## Security boundary

- The Windows instance has no public IP.
- RDP and ICMP are allowed only from the Client VPN address pool.
- The VPN endpoint can send traffic only to the POC VPC CIDR.
- Directory and test-user passwords are supplied only through AAP credentials.
- The test domain, username, certificate identifiers and organization tags are
  environment/customer configuration rather than reusable-module constants.

## Destroy authorization

```yaml
terraform_stack: client-vpn-ad-poc
terraform_destroy_enabled: true
terraform_allow_client_vpn_ad_poc_destroy: true
terraform_destroy_confirmation: DESTROY CLIENT VPN AD POC
```

Use the same `public_key`, certificate ARNs, authentication mode and access
group SID used for the final apply so Terraform evaluates the same state.

## Production integration boundary

This root is a validation harness, not the final production lifecycle design.
Directory-authenticated Client VPN depends on both Platform networking and the
Identity directory. After the proof, an Access stack should be evaluated to
consume both contracts without creating a Platform-to-Identity dependency
cycle.
