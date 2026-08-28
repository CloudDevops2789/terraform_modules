# Private AAP Environment Configuration

Organization-specific Terraform values must not be committed to the reusable
public repository.

AAP may supply approved, non-sensitive environment configuration through the
private inventory variable:

~~~yaml
terraform_environment_variables_by_stack:
  common:
    organization_tag_key_prefix: "<APPROVED_TAG_PREFIX>"
    org_it_cost_center: "<APPROVED_VALUE>"
    org_department: "<APPROVED_VALUE>"
    org_cmdb_calculated_app: "<APPROVED_VALUE>"
    org_business_criticality: "<APPROVED_VALUE>"
    org_environment: "<APPROVED_VALUE>"
    org_data_classification: "<APPROVED_VALUE>"
    org_project_name: "<APPROVED_VALUE>"
    org_managed_by: "<APPROVED_VALUE>"
    org_additional_tags: {}

  platform:
    security_group_naming_mode: standard

  identity:
    managed_ad_enabled: true
    managed_ad_configuration:
      domain_name: "<APPROVED_DIRECTORY_FQDN>"
      edition: Standard
~~~

These values are:

- controlled by the approved private AAP inventory;
- restricted through stack-specific allowlists;
- separate from operator `terraform_variables`;
- prohibited from replacing lifecycle contracts, AWS Region, or credentials;
- written only to the protected temporary Terraform variable document.

The Managed AD bootstrap password is not an environment variable. It remains
owned by the AAP custom credential that injects
`IRE_TERRAFORM_MANAGED_AD_PASSWORD`.

Client VPN certificate ARNs remain approved Platform runtime bindings. Client
VPN authentication type and enablement remain Git-controlled.
