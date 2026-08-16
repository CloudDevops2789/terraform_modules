# Ansible Automation Platform Integration

AAP is the orchestration and execution layer for the Terraform-based AWS
Isolated Recovery Environment.

Terraform remains responsible for AWS infrastructure desired state.

## Responsibility boundary

~~~text
Git
  -> reviewed architecture and security policy

AAP Job Template / Inventory / Credential
  -> execution role
  -> deployment Region
  -> backend binding
  -> approved external AWS resource references

AAP Survey / runtime
  -> plan or apply
  -> demo workload lifecycle
  -> approved regional AMI
  -> destroy authorization

Terraform
  -> AWS infrastructure graph and lifecycle
~~~

## Git-controlled desired state

## Git-controlled desired state

AAP explicitly supplies the Git-controlled variable files for the selected
Terraform lifecycle stack.

For Sandbox, these files are stored under:

~~~text
terraform/environments/sandbox/stacks/
  common-tags.tfvars
  platform.tfvars
  platform-network-policy.tfvars
  identity.tfvars
  recovery.tfvars
~~~

Only the files associated with the selected `terraform_stack` are passed to
Terraform.

These contain stable non-sensitive architecture and security policy.

AAP must not normally override them.
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
