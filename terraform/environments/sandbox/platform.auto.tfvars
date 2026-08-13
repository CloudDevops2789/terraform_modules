################################################################################
# Sandbox Platform Desired State
################################################################################
#
# This file contains Git-controlled architecture and security decisions.
#
# AAP controls execution/runtime intent and environment-specific external
# bindings. AAP must not be used as an architecture editor.
#
# Real enterprise IPAM allocations belong in the private enterprise deployment
# repository. The reusable repository intentionally uses neutral example CIDRs.
################################################################################

################################################################################
# Network architecture
################################################################################

# Sandbox/development cost-saving mode.
# Enterprise production changes to "firewall" through Git review.
network_inspection_mode = "bypass"

network_config = {
  account_cidr_block    = "10.100.0.0/22"
  client_vpn_cidr_block = "172.30.240.0/22"

  vpcs = {
    recovery_access = {
      cidr_block = "10.100.0.0/24"

      subnet_cidrs = {
        client_vpn_a      = "10.100.0.0/27"
        client_vpn_b      = "10.100.0.32/27"
        admin_tools_a     = "10.100.0.64/27"
        admin_tools_b     = "10.100.0.96/27"
        endpoints_a       = "10.100.0.128/28"
        endpoints_b       = "10.100.0.144/28"
        transit_gateway_a = "10.100.0.160/28"
        transit_gateway_b = "10.100.0.176/28"
      }
    }

    core_recovery = {
      cidr_block = "10.100.1.0/24"

      subnet_cidrs = {
        recovery_services_a  = "10.100.1.0/26"
        recovery_services_b  = "10.100.1.64/26"
        directory_services_a = "10.100.1.128/28"
        directory_services_b = "10.100.1.144/28"
        endpoints_a          = "10.100.1.160/28"
        endpoints_b          = "10.100.1.176/28"
        transit_gateway_a    = "10.100.1.192/28"
        transit_gateway_b    = "10.100.1.208/28"
      }
    }

    protected_data = {
      cidr_block = "10.100.2.0/24"

      subnet_cidrs = {
        protected_workloads_a = "10.100.2.0/27"
        protected_workloads_b = "10.100.2.32/27"
        ingestion_a           = "10.100.2.64/28"
        ingestion_b           = "10.100.2.80/28"
        database_a            = "10.100.2.96/28"
        database_b            = "10.100.2.112/28"
        file_services_a       = "10.100.2.128/28"
        file_services_b       = "10.100.2.144/28"
        endpoints_a           = "10.100.2.160/28"
        endpoints_b           = "10.100.2.176/28"
        transit_gateway_a     = "10.100.2.192/28"
        transit_gateway_b     = "10.100.2.208/28"
      }
    }

    inspection = {
      cidr_block = "10.100.3.0/24"

      subnet_cidrs = {
        firewall_a        = "10.100.3.0/28"
        firewall_b        = "10.100.3.16/28"
        transit_gateway_a = "10.100.3.32/28"
        transit_gateway_b = "10.100.3.48/28"
      }
    }
  }
}

################################################################################
# Client VPN architecture
################################################################################

# Allows the core IRE platform to bootstrap before PKI/Identity prerequisites
# are available.
client_vpn_enabled = false

# Enterprise target authentication pattern.
# MFA is enforced by the enterprise identity provider.
authentication_type = "federated"

# Enterprise IAM/Identity team owns the SAML provider.
manage_saml_provider = false

################################################################################
# Recovery workload administration
################################################################################

# Approved administration method for representative validation compute.
demo_ec2_access_method = "ssm"

# Persistent private SSM connectivity.
ssm_management_plane_enabled = true

# Sandbox creates the SSM role/profile.
# Enterprise may change this to "external" through Git review.
ssm_instance_profile_mode = "terraform"

################################################################################
# Optional Foundation integrations
################################################################################

backup_integration_enabled       = false
network_firewall_logging_enabled = false

################################################################################
# Enterprise-neutral governance metadata
################################################################################

org_it_cost_center       = "999999999"
org_department           = "cloud"
org_cmdb_calculated_app  = "cloud_app"
org_business_criticality = "4"
org_environment          = "dev"
org_data_classification  = "Internal"
org_project_name         = "AWS-IRE"
org_managed_by           = "Terraform"

org_additional_tags = {}

################################################################################
# Naming
################################################################################

naming = {
  organization             = "org"
  project                  = "ire"
  project_display_name     = "IRE"
  environment              = "sandbox"
  environment_display_name = "Sandbox"

  # Terraform derives this from the AAP-supplied aws_region.
  region_code = null

  suffix = null
}

resource_name_overrides = {}
