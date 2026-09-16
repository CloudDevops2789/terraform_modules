# Private AAP Environment Configuration

Organization-specific Terraform values must not be committed to the reusable
public repository.

AAP may supply approved, non-sensitive environment configuration through the
private inventory variable:

~~~yaml
terraform_environment_variables_by_stack:
  common:
    organization_tags:
      "<ORGANIZATION_TAG_KEY>": "<APPROVED_VALUE>"

  platform:
    security_group_naming_mode: standard

  identity:
    managed_ad_enabled: true
    managed_ad_configuration:
      domain_name: "<APPROVED_DIRECTORY_FQDN>"
      edition: Standard
      enable_directory_data_access: true
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

Set `enable_directory_data_access` to `true` only when approved automation
manages directory users or groups through the Directory Service Data API. This
keeps Terraform ownership aligned with the AAP user-provisioning workflow and
prevents a later Identity plan from disabling the API after AAP enables it.

Client VPN certificate ARNs remain approved Remote Access runtime bindings.
Remote Access authentication type and enablement remain Git-controlled.
