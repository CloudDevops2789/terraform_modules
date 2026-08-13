# Sandbox Environment

The Sandbox is the integrated Terraform root for the AWS Isolated Recovery
Environment. It composes four VPCs, Transit Gateway segmentation, centralized
AWS Network Firewall inspection, optional administrative Client VPN access, security
groups, representative EC2 resources, persistent-foundation integrations, and AWS Backup policy modules.

> **Current status:** Terraform configuration, AAP orchestration, and recovery-workload lifecycle behavior have been validated. Environment-specific runtime evidence is maintained separately from reusable documentation.

## Portable inputs

The Sandbox separates stable desired state from execution-time bindings.

Tracked desired state:

~~~text
platform.auto.tfvars
network-policy.auto.tfvars
~~~

`platform.auto.tfvars` owns stable non-sensitive architecture such as:

- VPC and subnet allocation;
- Client VPN client CIDR;
- inspection mode;
- Client VPN enablement and authentication mode;
- SSM management-plane design;
- naming;
- tagging; and
- Foundation integration enablement.

`network-policy.auto.tfvars` owns security-group and Network Firewall policy.

`terraform.tfvars.example` documents local/runtime and external bindings.
`terraform.tfvars` remains ignored.

AAP supplies the deployment Region, backend binding, approved temporary AMI,
and externally managed resource references. It does not normally redefine the
network or security architecture.

The reusable repository intentionally uses enterprise-neutral example
allocations. Real organization IPAM values belong in the approved private
environment/deployment configuration.

## Four-VPC topology

### Recovery Access

Subnet groups:

- `client-vpn`
- `admin-tools`
- `endpoints`
- `transit-gateway`

Client VPN associates only with the `client-vpn` subnets. Administrators reach
approved management hosts in the `admin-tools` subnets.

### Core Recovery

Subnet groups:

- `recovery-services`
- `directory-services`
- `endpoints`
- `transit-gateway`

Core Recovery hosts recovery tooling and the administrative control plane.

### Protected Data

Subnet groups:

- `protected-workloads`
- `ingestion`
- `database`
- `file-services`
- `endpoints`
- `transit-gateway`

Protected Data has no direct route from Recovery Access or Client VPN.

### Centralized Inspection

Subnet groups:

- `network-firewall`
- `transit-gateway`

Two firewall subnets and two Transit Gateway attachment subnets are distributed
across two Availability Zones. The Inspection attachment enables appliance mode.

The Inspection VPC has no Internet Gateway, NAT Gateway, public subnet, or
internet default route.

## Approved traffic model

| Flow | Treatment |
|---|---|
| Recovery Access ↔ Core Recovery | Inspected centrally |
| Core Recovery ↔ Protected Data | Inspected centrally |
| Recovery Access ↔ Protected Data | No route |
| Client VPN → Recovery Access admin host | Local Recovery Access path; no firewall hairpin |
| Admin host → Core Recovery | Inspected centrally |
| Site-to-Site VPN → Core Recovery | Planned; must traverse inspection |
| Site-to-Site VPN → Protected Data | No general route |
| Intra-VPC traffic | Security groups and workload controls |

## Centralized inspection path

```text
Source spoke subnet
  → source VPC route table
  → Transit Gateway
  → source TGW route table
  → Inspection VPC attachment
  → same-AZ Network Firewall endpoint
  → Inspection TGW route table
  → destination attachment
  → destination VPC route table
  → destination subnet
```

The return path uses the same Availability Zone and firewall endpoint.

### Transit Gateway policy

- Default route-table association is disabled.
- Default route propagation is disabled.
- Spoke attachments propagate only into the Inspection TGW route table.
- Spoke TGW route tables contain explicit static routes to the Inspection
  attachment.
- The Inspection TGW route table learns the three spoke CIDRs.
- Recovery Access and Protected Data never learn or receive a direct route to
  one another.

## Network Firewall policy

The Sandbox deploys:

- one centralized two-AZ firewall;
- one strict-order stateful segmentation rule group;
- one strict-order firewall policy;
- stateless forwarding to the stateful engine;
- default strict drop and alert actions;
- metadata analysis for HTTP host and TLS SNI;
- no TLS decryption.

The approved stateful trust relationships are:

```text
Recovery Access ↔ Core Recovery ↔ Protected Data
```

Security groups continue to enforce workload-level protocols and ports.

## Encrypted logging

Network Firewall sends separate `ALERT` and `FLOW` logs to CloudWatch Logs.

The log-group names are derived from portable naming inputs. Both log groups:

- retain data for 30 days in the current example;
- consume a dedicated customer-managed KMS key owned by the persistent Foundation state;
- use the regional CloudWatch Logs service principal;
- restrict KMS use with the log-group encryption context;
- remain outside the disposable Sandbox lifecycle.

TLS logging is disabled because TLS decryption is not configured.

## Client VPN boundary

Client VPN is an optional Recovery Access capability.

Initial platform bootstrap:

~~~hcl
client_vpn_enabled  = false
authentication_type = "federated"
~~~

No Client VPN endpoint, SAML-provider composition or Client VPN target-network
association is created in this state, and Client VPN PKI/identity dependencies
do not block the persistent IRE platform build.

After enterprise PKI and Identity prerequisites are available, a reviewed Git
change sets:

~~~hcl
client_vpn_enabled = true
~~~

For the enterprise federated pattern, AAP then supplies the existing server
certificate ARN and IAM SAML provider ARN.

The Client VPN endpoint associates only with the Recovery Access `client-vpn`
subnets and authorization remains scoped to approved Recovery Access
destinations.

There is no direct Client VPN route to Protected Data.

Intended administrative flow when Client VPN is enabled:

~~~text
Administrator
  -> AWS Client VPN
  -> Recovery Access
  -> approved segmented path
  -> Core Recovery
~~~

SSM remains the preferred private administrative mechanism for representative
validation EC2 instances once inside the AWS management boundary.

## Routing ownership

- `module.vpc` creates VPC-local networking resources and no routes.
- `module.transit_gateway` creates TGW attachments, TGW route tables,
  associations, and propagation.
- `module.network_firewall_routing` creates standalone VPC routes and static TGW
  routes.
- The environment owns topology, security intent, and route composition.

## Local setup

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
```

Do not commit either local file.

## Initialize, validate, and plan

```bash
terraform init \
  -input=false \
  -reconfigure \
  -backend-config=backend.hcl

terraform fmt -check -recursive
terraform validate

terraform plan \
  -input=false \
  -var-file=terraform.tfvars \
  -out=tfplan
```

Current empty-state expectation:

```text
Plan: 187 to add, 0 to change, 0 to destroy.
```

Review and remove the plan:

```bash
terraform show tfplan
rm -f tfplan
```

No Sandbox apply is part of the current validation workflow.

## Required plan checks

Confirm that the plan contains:

- four VPCs;
- no Internet Gateway or NAT Gateway;
- no IPv4 or IPv6 default route;
- four TGW VPC attachments;
- four TGW route-table associations;
- three TGW route propagations;
- four static spoke TGW routes to the Inspection attachment;
- one Network Firewall, policy, and stateful rule group;
- same-AZ endpoint routing;
- encrypted `ALERT` and `FLOW` logging;
- no direct Recovery Access-to-Protected Data route.

## Implemented versus planned

Implemented in Terraform:

- four-VPC topology;
- centralized Network Firewall;
- inspected adjacent-zone paths;
- encrypted firewall logging;
- Recovery Access Client VPN;
- security groups;
- representative EC2 resources;
- persistent Foundation references and AWS Backup policy composition;
- portable network and naming inputs.

Planned, not implemented:

- Site-to-Site VPN and hybrid TGW route table;
- runtime packet-flow and failover testing;
- narrowly scoped on-premises ingestion exception, if approved;
- production PKI-backed TLS decryption;
- production lifecycle protection settings.

## Persistent IRE Foundation Dependency

The Sandbox is the disposable recovery-environment Terraform root.

It does not own long-lived AWS Backup vaults or the customer-managed
KMS key used for Network Firewall logging.

Those resources are owned by the separate `foundation` Terraform
environment and are supplied through `foundation_resources`.

Example:

    foundation_resources = {
      standard_backup_vault_name = "approved-standard-vault-name"
      air_gapped_backup_vault_arn = "approved-air-gapped-vault-arn"
      network_firewall_logging_kms_key_arn = "approved-kms-key-arn"
    }

This lifecycle boundary ensures that destroying the Sandbox does not
attempt to delete retained backup vaults or persistent encryption keys.

<!-- BEGIN DEMO-WORKLOAD-LIFECYCLE -->

## Demonstration Workload Lifecycle and Administrative Access

The Sandbox separates the persistent IRE platform from temporary representative
compute used for connectivity and recovery-flow validation.

~~~mermaid
flowchart TD
    A[Persistent IRE Platform] --> B[Recovery Access VPC]
    A --> C[Core Recovery VPC]
    A --> D[Protected Data VPC]
    A --> E[Transit and Security Controls]

    F{SSM management plane enabled?} -->|Yes| G[Private SSM and SSMMessages Endpoints]
    G --> B
    G --> C
    G --> D

    H{demo_ec2_enabled} -->|false| I[Platform remains ready without demo compute]
    H -->|true| J[Temporary Representative EC2 Instances]

    J --> K{demo_ec2_access_method}
    K -->|none| L[No interactive administrative access]
    K -->|ssm| M[Systems Manager Session Manager]
    K -->|ssh_key| N[SSH key-based access]
~~~

### Persistent versus temporary resources

The following platform capabilities remain independent of the demonstration
EC2 lifecycle:

- VPCs and subnets
- route tables and routing controls
- Transit Gateway connectivity and segmentation
- baseline security groups and network controls
- Client VPN when `client_vpn_enabled = true` and other configured access-plane services
- private Systems Manager endpoints when `ssm_management_plane_enabled = true`
- Terraform-managed Systems Manager IAM capability when enabled

The representative Management, Core Recovery, and Protected Data EC2 instances
are temporary validation workloads.

Setting:

~~~hcl
demo_ec2_enabled = false
~~~

retains the platform without creating the representative EC2 instances.

Changing:

~~~hcl
demo_ec2_enabled = true
~~~

to:

~~~hcl
demo_ec2_enabled = false
~~~

and performing a normal Terraform plan and apply removes the demonstration
compute while preserving persistent platform resources.

Do not use a full environment destroy merely to remove demonstration compute.

### Administrative access methods

`demo_ec2_access_method` supports three values.

| Value | Purpose | SSH public key | EC2 instance profile |
|---|---|---|---|
| `none` | No interactive administrative access | Not required | Not required |
| `ssm` | AWS Systems Manager Session Manager | Not required | Required |
| `ssh_key` | SSH-key compatibility/testing | Required | Not required by this access method |

`ssm` is the preferred private administrative-access pattern where the
organization has approved Systems Manager.

The approved AMI must contain a functioning Systems Manager Agent when SSM
access is selected.

Operator permissions to start or control Session Manager sessions are separate
from the EC2 instance role and should be governed through the organization's
identity and privileged-access model.

### Systems Manager instance-profile modes

`ssm_instance_profile_mode` supports:

- `external` - consume an organization-managed EC2 instance profile.
- `terraform` - create the EC2 role and instance profile through the reusable
  IAM module.

When `external` is used for an SSM-enabled demonstration deployment,
`ssm_instance_profile_name` must identify the approved existing profile.

This allows the same Terraform configuration to operate in environments where
IAM lifecycle is centrally controlled as well as environments where Terraform
is authorized to manage the required IAM resources.

### Private Systems Manager connectivity

When:

~~~hcl
ssm_management_plane_enabled = true
~~~

the Sandbox creates private interface endpoints for:

- Systems Manager (`ssm`)
- Systems Manager messages (`ssmmessages`)

in the endpoint subnets of:

- Recovery Access
- Core Recovery
- Protected Data

No Systems Manager endpoint is created in the Inspection VPC.

Endpoint security groups permit HTTPS on TCP 443 only from the corresponding
workload security group for that trust tier.

Additional endpoints such as CloudWatch Logs or S3 should be enabled separately
when required by the organization's session logging, software distribution, or
management policy.

## Terraform Variable File Examples

Stable architecture is already loaded automatically from tracked
`.auto.tfvars` files.

A local runtime file therefore needs only environment bindings.

Persistent platform example:

~~~hcl
aws_region       = "us-east-1"
demo_ec2_enabled = false
~~~

Exercise example:

~~~hcl
aws_region       = "us-east-1"
demo_ec2_enabled = true
ami_id           = "ami-0123456789abcdef0"
~~~

When Git enables federated Client VPN:

~~~hcl
server_certificate_arn = "arn:aws:acm:<region>:<account>:certificate/<id>"
saml_provider_arn      = "arn:aws:iam::<account>:saml-provider/<name>"
~~~

`demo_ec2_access_method`, SSM architecture, network allocation, inspection mode
and authentication mode are not normal local/runtime choices; they are
Git-controlled environment architecture.

Direct Terraform compatibility support for SSH-key mode remains available for
controlled testing, but it is not part of the standard enterprise AAP
interface.

## AAP Variable Examples

AAP uses a much smaller runtime contract than the full Terraform root
interface.

Initial persistent platform:

~~~yaml
terraform_environment: sandbox
terraform_apply_enabled: false

terraform_variables: {}
~~~

The deployment Region is supplied once through:

~~~yaml
assume_role_aws_region: "us-east-1"
~~~

and the playbook injects that value into Terraform as `aws_region`.

Exercise:

~~~yaml
terraform_variables:
  demo_ec2_enabled: true
  ami_id: "<APPROVED_AMI>"
~~~

Federated Client VPN after Git enablement:

~~~yaml
terraform_variables:
  server_certificate_arn: "<ACM_SERVER_CERTIFICATE_ARN>"
  saml_provider_arn: "<ENTERPRISE_IAM_SAML_PROVIDER_ARN>"
~~~

AAP does not expose routine selections for:

- `network_config`;
- `network_inspection_mode`;
- `authentication_type`;
- `demo_ec2_access_method`;
- SSM architecture;
- naming;
- tags; or
- security policy.

Those values require Git review.

## Operational Lifecycle

A typical exercise lifecycle is:

~~~mermaid
flowchart LR
    A[Deploy Persistent Platform] --> B[Validate Platform Controls]
    B --> C[Enable Demo Compute]
    C --> D[Validate Recovery Traffic]
    D --> E[Perform Exercise]
    E --> F[Set demo_ec2_enabled false]
    F --> G[Terraform Plan]
    G --> H[Terraform Apply]
    H --> I[Demo Compute Removed]
    I --> J[Persistent IRE Platform Remains]
~~~

A full Terraform destroy is reserved for deliberate environment teardown and
is not part of the normal demonstration-workload lifecycle.

<!-- END DEMO-WORKLOAD-LIFECYCLE -->
