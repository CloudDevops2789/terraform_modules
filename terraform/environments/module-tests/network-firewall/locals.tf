locals {
  ##################################################################################################
  # Test Topology
  ##################################################################################################
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  firewall_subnets = {
    for index, availability_zone in local.availability_zones :
    availability_zone => {
      availability_zone = availability_zone
      cidr_block        = cidrsubnet(var.vpc_cidr, 8, index)
    }
  }
  org_required_tags = {
    org_it_cost_center       = var.org_it_cost_center
    org_department           = var.org_department
    org_cmdb_calculated_app  = var.org_cmdb_calculated_app
    org_business_criticality = var.org_business_criticality
    org_environment          = var.org_environment
    org_data_classification  = var.org_data_classification
    org_project_name         = var.org_project_name
    org_managed_by           = var.org_managed_by
  }

  org_tags = merge(
    var.org_additional_tags,
    local.org_required_tags
  )
  ##################################################################################################
  # Supporting Firewall Policy
  ##################################################################################################
  firewall_policies = {
    inspection = {
      name        = "module-test-network-firewall-policy"
      description = "Minimal policy supporting the Network Firewall module test."
      firewall_policy = {
        stateless_default_actions = [
          "aws:forward_to_sfe"
        ]
        stateless_fragment_default_actions = [
          "aws:forward_to_sfe"
        ]
      }
    }
  }
}
