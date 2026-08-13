# Sandbox Environment

The Sandbox is the integrated Terraform root for the AWS Isolated Recovery
Environment. It composes four VPCs, Transit Gateway segmentation, centralized
AWS Network Firewall inspection, administrative Client VPN access, security
groups, representative EC2 resources, persistent-foundation integrations, and AWS Backup policy modules.

> **Current status:** formatted, validated, and planned successfully. No
> Terraform apply was performed during the current implementation work.

## Portable inputs

Environment-specific values are defined in the selected `.tfvars` file:

- `network_config` contains the account allocation, VPC CIDRs, subnet CIDRs,
  Client VPN CIDR, and future hybrid network ranges.
- `naming` supplies standard naming components.
- `resource_name_overrides` permits exact organization-approved names without
  changing Terraform logical keys.
- `org_*` variables supply mandatory enterprise tags.

`terraform.tfvars.example` is shareable. `terraform.tfvars` is local and ignored.

The example file currently demonstrates the approved Sandbox allocation:

| Logical network | Example CIDR |
|---|---|
| Account allocation | `10.213.252.0/22` |
| Recovery Access | `10.213.252.0/24` |
| Core Recovery | `10.213.253.0/24` |
| Protected Data | `10.213.254.0/24` |
| Centralized Inspection | `10.213.255.0/24` |
| Client VPN clients | `192.168.0.0/16` |

These are input values, not hardcoded reusable-module assumptions.

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

Client VPN terminates in Recovery Access. The Sandbox currently defines:

- mutual certificate authentication;
- target-network associations in Recovery Access;
- authorization only for the Recovery Access CIDR;
- no explicit Client VPN route to Core Recovery;
- no Client VPN route to Protected Data.

The intended administrative flow is:

```text
Administrator
  → Client VPN
  → Recovery Access admin host
  → centralized inspection
  → Core Recovery
```

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
- Client VPN and other configured access-plane services
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

The same Terraform variable contract can be supplied through a Terraform
variable file or through AAP `terraform_variables`.

### Persistent platform only

~~~hcl
demo_ec2_enabled              = false
demo_ec2_access_method        = "none"
ssm_management_plane_enabled  = false
ssm_instance_profile_mode     = "external"
~~~

Neither `ami_id` nor `public_key_path` is required.

### Persistent SSM management plane without demo compute

~~~hcl
demo_ec2_enabled              = false
demo_ec2_access_method        = "none"

ssm_management_plane_enabled  = true
ssm_instance_profile_mode     = "external"
~~~

This keeps the private Systems Manager connectivity ready without creating the
representative EC2 instances.

### Demo compute with SSM and Terraform-managed instance profile

~~~hcl
demo_ec2_enabled              = true
demo_ec2_access_method        = "ssm"
ami_id                        = "ami-0123456789abcdef0"

ssm_management_plane_enabled  = true
ssm_instance_profile_mode     = "terraform"
~~~

No SSH public key is required.

### Demo compute with an existing enterprise instance profile

~~~hcl
demo_ec2_enabled              = true
demo_ec2_access_method        = "ssm"
ami_id                        = "ami-0123456789abcdef0"

ssm_management_plane_enabled  = true
ssm_instance_profile_mode     = "external"
ssm_instance_profile_name     = "org-approved-ire-ssm-profile"
~~~

The supplied profile is consumed but is not created or modified by this
Terraform configuration.

### Demo compute with SSH-key access

~~~hcl
demo_ec2_enabled       = true
demo_ec2_access_method = "ssh_key"
ami_id                 = "ami-0123456789abcdef0"

public_key_path = "/approved/path/ire-demo.pub"
~~~

SSH-key mode is provided for compatibility and controlled testing. Network
reachability and security-group policy must still explicitly permit SSH where
required.

## AAP Variable Examples

AAP supplies the same Terraform inputs through the `terraform_variables`
mapping.

### AAP - persistent platform only

~~~yaml
terraform_environment: sandbox
terraform_apply_enabled: false

terraform_variables:
  demo_ec2_enabled: false
  demo_ec2_access_method: none

  ssm_management_plane_enabled: false
  ssm_instance_profile_mode: external
~~~

### AAP - demo compute using SSM

~~~yaml
terraform_environment: sandbox
terraform_apply_enabled: false

terraform_variables:
  demo_ec2_enabled: true
  demo_ec2_access_method: ssm
  ami_id: ami-0123456789abcdef0

  ssm_management_plane_enabled: true
  ssm_instance_profile_mode: external
  ssm_instance_profile_name: org-approved-ire-ssm-profile
~~~

`terraform_public_key` is not required for SSM access.

### AAP - demo compute using SSH key

~~~yaml
terraform_environment: sandbox
terraform_apply_enabled: false

terraform_public_key: "ssh-ed25519 AAAA...approved-public-key"

terraform_variables:
  demo_ec2_enabled: true
  demo_ec2_access_method: ssh_key
  ami_id: ami-0123456789abcdef0
~~~

AAP writes the supplied public key to its temporary execution workspace and
injects the resulting temporary `public_key_path` into Terraform.

The public key is required only when both of the following are true:

~~~text
demo_ec2_enabled       = true
demo_ec2_access_method = ssh_key
~~~

It is not required for baseline-only, `none`, or `ssm` deployments.

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
