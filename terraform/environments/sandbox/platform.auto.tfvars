################################################################################
# Sandbox Platform Desired State
################################################################################
#
# PURPOSE
#
# This file is the Git-controlled desired-state contract for the integrated
# Sandbox IRE platform.
#
# Stable architecture and security decisions belong here and are changed through
# normal Git review / pull-request workflow.
#
# AAP is the execution and orchestration layer. It must not be used as a
# free-form architecture editor.
#
# OWNERSHIP MODEL
#
# Git / platform.auto.tfvars owns:
#   - network inspection mode;
#   - VPC and subnet CIDRs;
#   - Client VPN enablement and authentication architecture;
#   - SSM administration architecture;
#   - Foundation integration enablement;
#   - standard organization tags;
#   - naming policy; and
#   - approved resource-name overrides.
#
# Git / network-policy.auto.tfvars owns:
#   - security-group policy; and
#   - Network Firewall policy.
#
# AAP top-level environment bindings own:
#   - AWS execution role;
#   - deployment Region through assume_role_aws_region;
#   - Terraform backend bucket/key/Region; and
#   - plan/apply/destroy workflow control.
#
# The deploy/destroy playbooks derive Terraform aws_region automatically from:
#
#   assume_role_aws_region
#
# terraform_backend_region remains independent because the Terraform state
# bucket may reside in a different AWS Region.
#
# AAP terraform_variables is intentionally restricted to approved runtime or
# externally managed resource bindings, currently including:
#
#   demo_ec2_enabled
#   ami_id
#   server_certificate_arn
#   root_certificate_chain_arn
#   saml_provider_arn
#   ssm_instance_profile_name
#   foundation_resources
#
# Network topology, authentication mode, naming, tags, inspection mode, and SSM
# architecture must not be supplied through AAP terraform_variables.
#
# IMPORTANT
#
# This Sandbox composition contains its approved account network allocation.
# The reusable Terraform modules remain CIDR-agnostic.
#
# Changing a VPC or subnet CIDR for an existing deployed environment can force
# resource replacement. Always review a Terraform plan before applying network
# allocation changes.
################################################################################


################################################################################
# Network Architecture
################################################################################
#
# network_inspection_mode controls the inter-VPC routing architecture.
#
# Supported values:
#
#   "bypass"
#     Sandbox/development cost-saving mode.
#
#     AWS Network Firewall inspection is not placed in the active inter-VPC
#     traffic path. Approved adjacent-zone connectivity still uses Transit
#     Gateway segmentation.
#
#   "firewall"
#     Enterprise inspection mode.
#
#     Approved inter-VPC flows are routed through the centralized Inspection VPC
#     and AWS Network Firewall architecture.
#
# Ownership:
#
#   Git controlled.
#
# Do not expose this as an AAP launch-time choice. Moving an existing environment
# between bypass and firewall modes changes routing/security behavior and must be
# reviewed through Terraform plan and Git approval.
################################################################################

network_inspection_mode = "bypass"


################################################################################
# Network Allocation
################################################################################
#
# network_config defines the complete Sandbox address plan.
#
# Ownership:
#
#   Git / approved IPAM allocation.
#
# AAP must not override this structure.
#
# account_cidr_block:
#
#   Parent allocation reserved for the four IRE VPCs.
#
# client_vpn_cidr_block:
#
#   Address pool allocated to AWS Client VPN clients.
#
#   This pool is reserved in the architecture even when:
#
#     client_vpn_enabled = false
#
# VPC roles:
#
#   recovery_access
#     Administrative entry and management-access boundary.
#
#   core_recovery
#     Shared recovery services, directory services, management endpoints, and
#     platform services.
#
#   protected_data
#     Restored/recovered workloads, ingestion, databases, file services, and
#     associated private endpoints.
#
#   inspection
#     Centralized AWS Network Firewall and Transit Gateway inspection boundary.
#
# WARNING
#
# CIDR changes on existing VPCs/subnets can require destructive replacement.
# Never modify these values as a runtime workaround.
################################################################################

network_config = {
  account_cidr_block    = "10.213.252.0/22"
  client_vpn_cidr_block = "172.30.240.0/22"

  vpcs = {
    recovery_access = {
      cidr_block = "10.213.252.0/24"

      subnet_cidrs = {
        client_vpn_a      = "10.213.252.0/27"
        client_vpn_b      = "10.213.252.32/27"
        admin_tools_a     = "10.213.252.64/27"
        admin_tools_b     = "10.213.252.96/27"
        endpoints_a       = "10.213.252.128/28"
        endpoints_b       = "10.213.252.144/28"
        transit_gateway_a = "10.213.252.160/28"
        transit_gateway_b = "10.213.252.176/28"
      }
    }

    core_recovery = {
      cidr_block = "10.213.253.0/24"

      subnet_cidrs = {
        recovery_services_a  = "10.213.253.0/26"
        recovery_services_b  = "10.213.253.64/26"
        directory_services_a = "10.213.253.128/28"
        directory_services_b = "10.213.253.144/28"
        endpoints_a          = "10.213.253.160/28"
        endpoints_b          = "10.213.253.176/28"
        transit_gateway_a    = "10.213.253.192/28"
        transit_gateway_b    = "10.213.253.208/28"
      }
    }

    protected_data = {
      cidr_block = "10.213.254.0/24"

      subnet_cidrs = {
        protected_workloads_a = "10.213.254.0/27"
        protected_workloads_b = "10.213.254.32/27"
        ingestion_a           = "10.213.254.64/28"
        ingestion_b           = "10.213.254.80/28"
        database_a            = "10.213.254.96/28"
        database_b            = "10.213.254.112/28"
        file_services_a       = "10.213.254.128/28"
        file_services_b       = "10.213.254.144/28"
        endpoints_a           = "10.213.254.160/28"
        endpoints_b           = "10.213.254.176/28"
        transit_gateway_a     = "10.213.254.192/28"
        transit_gateway_b     = "10.213.254.208/28"
      }
    }

    inspection = {
      cidr_block = "10.213.255.0/24"

      subnet_cidrs = {
        firewall_a        = "10.213.255.0/28"
        firewall_b        = "10.213.255.16/28"
        transit_gateway_a = "10.213.255.32/28"
        transit_gateway_b = "10.213.255.48/28"
      }
    }
  }
}


################################################################################
# Client VPN Architecture
################################################################################
#
# Client VPN architecture is intentionally separated from the externally
# managed PKI and identity resources that the endpoint consumes.
#
# Git controls:
#
#   client_vpn_enabled
#   authentication_type
#   manage_saml_provider
#
# AAP supplies external environment bindings only when the selected Git
# architecture requires them.
#
# -------------------------------------------------------------------------------
# client_vpn_enabled
# -------------------------------------------------------------------------------
#
# false
#
#   Client VPN resources are not created.
#
#   The persistent IRE platform can therefore bootstrap before enterprise PKI
#   and Identity/SAML prerequisites are ready.
#
#   AAP does NOT need:
#
#     server_certificate_arn
#     root_certificate_chain_arn
#     saml_provider_arn
#
# true
#
#   Client VPN resources are created.
#
#   Required external AAP bindings depend on authentication_type.
#
# Ownership:
#
#   Git controlled.
################################################################################

client_vpn_enabled = false


################################################################################
# Client VPN Authentication Pattern
################################################################################
#
# Supported values:
#
#   "federated"
#
#     Enterprise target.
#
#     Authentication is performed through the enterprise SAML identity provider.
#     MFA is enforced by the enterprise identity provider, not by a separate
#     Terraform Client VPN MFA setting.
#
#     When:
#
#       client_vpn_enabled  = true
#       authentication_type = "federated"
#       manage_saml_provider = false
#
#     AAP terraform_variables must supply:
#
#       server_certificate_arn
#       saml_provider_arn
#
#     server_certificate_arn:
#
#       Existing ACM TLS server certificate used by the AWS Client VPN endpoint.
#       It must belong to the selected deployment Region.
#
#       This is NOT a per-user/client certificate.
#
#     saml_provider_arn:
#
#       Existing AWS IAM SAML provider owned by the approved Identity/IAM process.
#
#
#   "certificate"
#
#     Controlled lab / compatibility mode.
#
#     When:
#
#       client_vpn_enabled  = true
#       authentication_type = "certificate"
#
#     AAP terraform_variables must supply:
#
#       server_certificate_arn
#       root_certificate_chain_arn
#
#     root_certificate_chain_arn represents the approved certificate authority
#     used for mutual certificate authentication.
#
# Ownership:
#
#   Git controlled.
#
# Do not expose authentication_type as an AAP survey/runtime architecture choice.
################################################################################

authentication_type = "federated"


################################################################################
# IAM SAML Provider Ownership
################################################################################
#
# This setting is relevant to federated Client VPN authentication.
#
# false
#
#   Recommended enterprise model.
#
#   The IAM/Identity process owns the AWS IAM SAML provider.
#
#   When Client VPN is enabled with federated authentication, AAP supplies:
#
#     saml_provider_arn
#
#
# true
#
#   Terraform owns creation of the AWS IAM SAML provider.
#
#   Terraform-managed SAML requires approved SAML metadata in addition to the
#   provider name/configuration.
#
#   IMPORTANT:
#
#   Terraform-managed SAML is not currently part of the standard Sandbox AAP
#   runtime contract. Before selecting true for an AAP-driven enterprise
#   deployment, the governed automation interface must be explicitly extended
#   to supply approved SAML metadata.
#
# Ownership:
#
#   Git controlled.
################################################################################

manage_saml_provider = false


################################################################################
# Recovery Workload Administration
################################################################################
#
# demo_ec2_access_method defines the approved administrative-access architecture
# for representative temporary recovery-validation EC2 instances.
#
# It does NOT create the instances by itself.
#
# The runtime lifecycle switch is:
#
#   demo_ec2_enabled
#
# and is supplied through AAP terraform_variables.
#
# Normal persistent-platform bootstrap:
#
#   terraform_variables: {}
#
# or explicitly:
#
#   demo_ec2_enabled = false
#
# Exercise/runtime validation:
#
#   AAP terraform_variables:
#
#     demo_ec2_enabled = true
#     ami_id            = <approved AMI in the deployment Region>
#
# Supported demo_ec2_access_method values:
#
#   "ssm"
#
#     Enterprise-preferred private administration pattern.
#     No SSH public key is required.
#
#   "none"
#
#     Representative EC2 instances have no interactive administrative-access
#     method configured by this composition.
#
#   "ssh_key"
#
#     Compatibility / controlled testing mode.
#
#     This remains Terraform interface capability but is intentionally not part
#     of the normal enterprise Sandbox AAP runtime contract.
#
# Ownership:
#
#   Git controlled.
################################################################################

demo_ec2_access_method = "ssm"


################################################################################
# Persistent Systems Manager Management Plane
################################################################################
#
# true
#
#   Keeps private Systems Manager connectivity available as persistent platform
#   infrastructure.
#
#   The Sandbox creates private interface endpoints for:
#
#     ssm
#     ssmmessages
#
#   in:
#
#     Recovery Access
#     Core Recovery
#     Protected Data
#
#   This capability remains available even when:
#
#     demo_ec2_enabled = false
#
#
# false
#
#   Persistent private Systems Manager endpoint infrastructure is not created.
#
# Ownership:
#
#   Git controlled.
################################################################################

ssm_management_plane_enabled = true


################################################################################
# Systems Manager EC2 Instance-Profile Ownership
################################################################################
#
# Supported values:
#
#   "terraform"
#
#     Terraform creates and manages the EC2 IAM role / instance profile used for
#     SSM-managed representative recovery compute.
#
#     No ssm_instance_profile_name AAP binding is required.
#
#
#   "external"
#
#     Terraform consumes an already-approved enterprise EC2 instance profile.
#
#     AAP terraform_variables must supply:
#
#       ssm_instance_profile_name
#
#     Terraform consumes the external profile but does not create or modify it.
#
# Ownership:
#
#   Git controlled.
#
# Enterprise environments where IAM lifecycle is centrally managed may change
# this to "external" through Git review.
################################################################################

ssm_instance_profile_mode = "terraform"


################################################################################
# Optional Foundation Integrations
################################################################################
#
# The Foundation environment has a separate Terraform state and ownership
# boundary.
#
# Sandbox integrations are disabled until the corresponding persistent
# Foundation resources are available.
#
# AAP may supply external Foundation references through:
#
#   terraform_variables:
#     foundation_resources: {...}
#
# The exact Foundation references consumed depend on which integration is
# enabled.
################################################################################


################################################################################
# AWS Backup Integration
################################################################################
#
# false
#
#   Sandbox does not compose the optional Foundation-backed AWS Backup
#   integration.
#
# true
#
#   Sandbox consumes the approved Foundation backup resources required by the
#   recovery architecture.
#
#   AAP must provide the required external Foundation references through:
#
#     foundation_resources
#
# Ownership:
#
#   Enablement is Git controlled.
#   External Foundation resource identifiers are AAP environment bindings.
################################################################################

backup_integration_enabled = false


################################################################################
# AWS Network Firewall Logging Integration
################################################################################
#
# false
#
#   Foundation-backed Network Firewall logging integration is not enabled.
#
# true
#
#   Enables the configured Network Firewall logging integration and consumes the
#   required persistent Foundation logging/encryption references.
#
#   AAP must provide the required external Foundation references through:
#
#     foundation_resources
#
# Operational expectation:
#
#   This should normally be enabled only as part of the approved firewall-mode
#   architecture with the required Foundation logging/KMS resources available.
#
# Ownership:
#
#   Enablement is Git controlled.
#   External Foundation resource identifiers are AAP environment bindings.
################################################################################

network_firewall_logging_enabled = false


################################################################################
# Governance Metadata / Standard Tags
################################################################################
#
# These values represent stable environment governance metadata.
#
# Ownership:
#
#   Git / approved environment configuration.
#
# They are deliberately not part of the normal AAP runtime-variable interface.
#
# Production/private environment repositories should replace placeholder/example
# governance values with organization-approved values through normal review.
#
# org_additional_tags is the supported extension point for extra approved tags
# that are not part of the mandatory standard set.
################################################################################

org_it_cost_center       = "10000-70100-8281"
org_department           = "Cybersecurity_Resilience_and_Recovery"
org_cmdb_calculated_app  = "Cybersecurity_Resilience_and_Recovery"
org_business_criticality = "4"
org_environment          = "dev"
org_data_classification  = "Internal"
org_project_name         = "CyberRecoveryBlueprint"
org_managed_by           = "Terraform"

org_additional_tags = {}


################################################################################
# Naming Architecture
################################################################################
#
# Naming is stable desired state and therefore Git controlled.
#
# AAP must not normally override naming.
#
# region_code:
#
#   null is intentional.
#
#   Terraform derives the effective Region code from aws_region, and aws_region
#   is injected by the AAP playbook from:
#
#     assume_role_aws_region
#
#   Keeping region_code = null avoids a second independently maintained Region
#   value and reduces the chance of Region/name mismatches.
#
# suffix:
#
#   Optional stable naming suffix. Leave null when not required.
#
# WARNING
#
# Naming changes can produce resource-name changes and, depending on the AWS
# resource, may cause replacement. Review Terraform plan before applying.
################################################################################

naming = {
  organization             = "org"
  project                  = "ire"
  project_display_name     = "IRE"
  environment              = "sandbox"
  environment_display_name = "Sandbox"

  region_code = null

  suffix = null
}


################################################################################
# Exact Resource-Name Overrides
################################################################################
#
# Empty map:
#
#   Standard naming rules are used.
#
# Non-empty map:
#
#   Allows explicitly approved exact AWS resource names where organization
#   standards or integration constraints require them.
#
# Ownership:
#
#   Git controlled.
#
# Do not use resource_name_overrides as an AAP runtime mechanism.
#
# Changing an existing resource name may cause Terraform to replace the resource,
# depending on AWS provider/resource behavior.
################################################################################

resource_name_overrides = {}


################################################################################
# Common AAP Runtime Examples
################################################################################
#
# These examples are comments only. The values below are NOT defined by this
# file.
#
#
# 1. Initial persistent-platform bootstrap
#
#   terraform_variables: {}
#
#
# 2. Temporary representative recovery compute
#
#   terraform_variables:
#     demo_ec2_enabled: true
#     ami_id: "<APPROVED_AMI_IN_DEPLOYMENT_REGION>"
#
#
# 3. Federated Client VPN after Git enables Client VPN
#
#   Git:
#
#     client_vpn_enabled   = true
#     authentication_type  = "federated"
#     manage_saml_provider = false
#
#   AAP:
#
#     terraform_variables:
#       server_certificate_arn: "<ACM_SERVER_CERTIFICATE_ARN>"
#       saml_provider_arn: "<IAM_SAML_PROVIDER_ARN>"
#
#
# 4. Certificate-authenticated Client VPN
#
#   Git:
#
#     client_vpn_enabled  = true
#     authentication_type = "certificate"
#
#   AAP:
#
#     terraform_variables:
#       server_certificate_arn: "<ACM_SERVER_CERTIFICATE_ARN>"
#       root_certificate_chain_arn: "<ACM_ROOT_CA_ARN>"
#
#
# 5. External SSM instance-profile ownership
#
#   Git:
#
#     ssm_instance_profile_mode = "external"
#
#   AAP:
#
#     terraform_variables:
#       ssm_instance_profile_name: "<APPROVED_INSTANCE_PROFILE>"
#
#
# 6. Optional Foundation integration
#
#   Git enables the required integration.
#
#   AAP supplies:
#
#     terraform_variables:
#       foundation_resources:
#         <approved external Foundation references>
#
#
# Architecture values themselves must remain Git controlled.
################################################################################
