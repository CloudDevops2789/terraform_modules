# Ansible Automation Platform Integration

AAP is the orchestration and execution layer for the Terraform-based AWS
Isolated Recovery Environment.

Terraform remains responsible for AWS infrastructure desired state.

## Responsibility boundary

~~~text
Git
  -> reviewed architecture and security policy

AAP SCM inventory
  -> execution role and expected account
  -> deployment and backend Regions
  -> backend binding
  -> Persistent contract source

AAP Job Template / Credential
  -> fixed stack and lifecycle intent
  -> allowlisted external runtime bindings

AAP Survey / runtime
  -> plan or apply
  -> demo workload lifecycle
  -> destroy authorization

Terraform
  -> AWS infrastructure graph and lifecycle
~~~

## Git-controlled desired state

AAP explicitly supplies the Git-controlled variable files for the selected
Terraform lifecycle stack.

For Sandbox, these files are stored under:

~~~text
terraform/environments/sandbox/config/
  common-tags.tfvars
  persistent.tfvars
  platform.tfvars
  platform-network-policy.tfvars
  identity.tfvars
  recovery.tfvars
~~~

Only the files associated with the selected `terraform_stack` are passed to
Terraform.

These contain stable non-sensitive architecture and security policy.

AAP must not normally override them.

Recovery workload AMIs, access methods, and SSH key-pair references are part of
that reviewed Git configuration. AAP controls only whether the configured
temporary workloads are enabled for the exercise.

## Git-controlled environment inventory

Common execution bindings are sourced once from an approved SCM inventory
instead of being copied into every JT. See `inventories/example/` for the
customer-neutral structure.

The private environment inventory owns the target environment, role ARN,
expected account ID, deployment and backend Regions, backend bucket, and
Persistent Resources contract source. JTs own only the fixed stack, lifecycle
intent, destroy gates, and the allowlisted `terraform_variables` map.

Do not place real organization values in the customer-neutral example
inventory. Do not place environment bindings in an Execution Environment.

## Deployment Region

`assume_role_aws_region` is the AAP deployment-Region binding.

The Terraform deploy and destroy playbooks automatically inject the same value
as Terraform `aws_region`.

The Terraform backend Region remains a separate binding.

## Client VPN bootstrap

Client VPN is optional during initial platform bootstrap.

With:

~~~hcl
client_vpn_enabled = false
~~~

the persistent IRE platform can be created without a Client VPN server
certificate or SAML provider ARN.

The enterprise target remains federated authentication. After PKI and Identity
dependencies are available, enable Client VPN through a reviewed Git change and
supply the existing certificate/SAML ARNs through the approved AAP environment
binding.

## Runtime artifacts

The deploy and destroy playbooks create temporary runtime artifacts including:

- a restricted `.auto.tfvars.json` file;
- saved Terraform deployment plans; and
- saved Terraform destroy plans.

Temporary artifacts are removed by the playbook cleanup path.

AAP no longer materializes SSH public-key files for the normal Sandbox
orchestration path.

## Security

- AWS credentials are temporary STS credentials obtained by AssumeRole.
- Architecture changes require Git review.
- Sandbox runtime Terraform variables are allowlisted.
- Client VPN authentication mode is not a normal launch-time selection.
- SSM is the standard administrative pattern for representative validation
  compute.
- Sensitive values belong in AAP Credentials or approved secret-management
  systems.

## Documentation

See:

- `variables.md`
- `job-templates.md`
- `examples/`
- `../../inventories/README.md`
