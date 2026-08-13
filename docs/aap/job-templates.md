# AAP Job Template Design

AAP orchestrates Terraform execution while Git remains the source of truth for
stable IRE architecture.

## Operating principle

~~~text
AAP user chooses the operation.
Git determines the architecture.
~~~

The normal AAP launch must not expose free-form controls for VPC topology,
network inspection, Client VPN authentication mode, SSM architecture, naming,
tagging, or security policy.

## Deploy Job Template

Recommended fixed Job Template / Inventory bindings:

~~~yaml
terraform_environment: "sandbox"

assume_role_role_arn: "<APPROVED_AAP_EXECUTION_ROLE_ARN>"
assume_role_aws_region: "us-east-1"

terraform_backend_bucket: "<APPROVED_STATE_BUCKET>"
terraform_backend_key: "sandbox/terraform.tfstate"
terraform_backend_region: "<BACKEND_BUCKET_REGION>"
~~~

The playbook automatically supplies Terraform `aws_region` from
`assume_role_aws_region`.

Recommended launch control:

~~~yaml
terraform_apply_enabled: false
~~~

Initial persistent-platform bootstrap:

~~~yaml
terraform_variables: {}
~~~

Recovery exercise:

~~~yaml
terraform_variables:
  demo_ec2_enabled: true
  ami_id: "<APPROVED_AMI>"
~~~

## Client VPN enablement

Client VPN is intentionally optional during initial infrastructure bootstrap.

Initial Git state:

~~~hcl
client_vpn_enabled  = false
authentication_type = "federated"
manage_saml_provider = false
~~~

This allows the persistent IRE platform to deploy before the enterprise PKI and
Identity prerequisites are available.

After the prerequisites are ready:

1. PKI provides the approved Client VPN server certificate in ACM.
2. Identity/IAM provides the approved SAML integration and IAM SAML provider.
3. A reviewed Git change sets `client_vpn_enabled = true`.
4. AAP supplies the external bindings:

~~~yaml
terraform_variables:
  server_certificate_arn: "<ACM_SERVER_CERTIFICATE_ARN>"
  saml_provider_arn: "<ENTERPRISE_IAM_SAML_PROVIDER_ARN>"
~~~

The authentication mode itself remains Git controlled.

## Recommended AAP Survey

A normal Sandbox deployment survey should expose only operational intent such
as:

- plan versus approved apply;
- whether temporary demo compute is required; and
- an approved AMI identifier when demo compute is enabled.

Do not expose:

- network CIDRs;
- inspection bypass/firewall mode;
- Client VPN authentication mode;
- SSM versus SSH;
- naming;
- tagging;
- security rules;
- Terraform-managed SAML ownership; or
- arbitrary free-form `terraform_variables`.

## Destroy Job Template

Safe defaults:

~~~yaml
terraform_destroy_enabled: false
terraform_destroy_confirmation: ""
terraform_allow_foundation_destroy: false
~~~

Approved Sandbox destruction requires:

~~~yaml
terraform_destroy_enabled: true
terraform_destroy_confirmation: "DESTROY"
~~~

Foundation destruction remains separately protected and must use the dedicated
break-glass controls already implemented by the destroy workflow.

## Backend Region versus deployment Region

These values are intentionally independent.

~~~text
assume_role_aws_region
    -> AWS infrastructure deployment Region
    -> Terraform aws_region

terraform_backend_region
    -> Region containing the Terraform state bucket
~~~

Moving an IRE deployment from one AWS Region to another does not imply that the
remote-state bucket must also move.

## Execution Environment

The AAP Execution Environment must contain the repository-approved Terraform
CLI, Ansible dependencies, AWS SDK dependencies, and required enterprise trust
configuration.

Infrastructure deployment is performed through the approved AAP application
role. Manual AWS console configuration is not part of the intended workflow.

## Examples

See:

- `docs/aap/examples/deploy-job-vars.example.yml`
- `docs/aap/examples/destroy-job-vars.example.yml`
- `terraform/environments/sandbox/aap-extra-vars.example.yml`
