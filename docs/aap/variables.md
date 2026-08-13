# AAP and Terraform Variable Ownership

The deployment model intentionally separates **architecture**, **environment
bindings**, and **runtime intent**.

AAP is an execution/orchestration interface. It is not the normal interface for
changing IRE network or security architecture.

## Ownership model

| Layer | Owner | Examples |
|---|---|---|
| Desired architecture | Git / Pull Request | VPC CIDRs, subnets, inspection mode, Client VPN enable/auth mode, SSM design, naming, tags |
| Security policy | Git / Pull Request | Security-group rules and Network Firewall rules |
| Environment binding | AAP Job Template / Inventory / Credential | execution role, deployment Region, backend, certificate ARN, SAML provider ARN |
| Runtime intent | AAP launch / Survey | plan/apply, demo workload on/off, approved AMI, destroy confirmation |
| Secrets | AAP Credential / approved secret manager | credentials, passwords, private keys, protected tokens |

## Git-controlled Terraform inputs

The Sandbox stores stable non-sensitive desired state in:

~~~text
terraform/environments/sandbox/platform.auto.tfvars
terraform/environments/sandbox/network-policy.auto.tfvars
~~~

Examples include:

- `network_config`;
- `network_inspection_mode`;
- `client_vpn_enabled`;
- `authentication_type`;
- `manage_saml_provider`;
- `demo_ec2_access_method`;
- `ssm_management_plane_enabled`;
- `ssm_instance_profile_mode`;
- organization tagging;
- naming;
- Foundation integration enablement;
- security-group policy; and
- Network Firewall policy.

These values must not be supplied through the normal Sandbox AAP runtime map.

## AAP environment bindings

The Job Template or Inventory supplies:

| Variable | Purpose |
|---|---|
| `assume_role_role_arn` | Approved AWS execution role |
| `assume_role_aws_region` | Deployment Region and Terraform `aws_region` source of truth |
| `terraform_backend_bucket` | Terraform remote-state bucket |
| `terraform_backend_key` | Environment state key |
| `terraform_backend_region` | Region containing the state bucket |

`terraform_backend_region` is intentionally independent from
`assume_role_aws_region`.

The playbooks automatically inject:

~~~text
aws_region = assume_role_aws_region
~~~

into the temporary Terraform runtime variable file.

## Sandbox terraform_variables allowlist

`terraform_variables` is intentionally restricted to runtime or externally
managed resource bindings.

Allowed Sandbox keys are:

| Variable | Purpose |
|---|---|
| `demo_ec2_enabled` | Enable temporary representative recovery-validation compute |
| `ami_id` | Approved AMI in the deployment Region |
| `server_certificate_arn` | Existing ACM server certificate when Client VPN is enabled |
| `root_certificate_chain_arn` | Existing root CA ARN when certificate authentication is deliberately selected |
| `saml_provider_arn` | Existing enterprise IAM SAML provider for federated Client VPN |
| `ssm_instance_profile_name` | Existing enterprise SSM profile when Git selects external ownership |
| `foundation_resources` | External Foundation resource references for enabled integrations |

Any other Sandbox key fails before Terraform execution.

## Client VPN bootstrap lifecycle

Initial infrastructure bootstrap:

~~~text
Git:
  client_vpn_enabled  = false
  authentication_type = federated

AAP:
  no Client VPN certificate/SAML ARN required
~~~

The VPCs, Transit Gateway, routing, security controls, SSM management plane, and
other persistent platform capabilities can therefore be deployed without
waiting for PKI or Identity integration.

After enterprise dependencies exist:

~~~text
PKI:
  server certificate available in ACM

Identity/IAM:
  enterprise SAML application and IAM SAML provider available

Git PR:
  client_vpn_enabled = true

AAP environment binding:
  server_certificate_arn
  saml_provider_arn
~~~

MFA policy is owned by the enterprise identity provider.

Mutual certificate authentication remains supported by the reusable Client VPN
interface for controlled use cases, but it is not the default enterprise AAP
access model.

## Demo workload lifecycle

Normal persistent platform:

~~~yaml
terraform_variables:
  demo_ec2_enabled: false
~~~

Exercise:

~~~yaml
terraform_variables:
  demo_ec2_enabled: true
  ami_id: "<APPROVED_AMI>"
~~~

The administration method is not a launch-time selection. Git defines the
approved environment access model, with SSM as the standard Sandbox pattern.

## Sensitive values

Never place credentials, passwords, private keys, access keys, or other
sensitive material in tracked Terraform variable files or AAP examples.

Use AAP Credentials or the approved enterprise secret-management mechanism.
