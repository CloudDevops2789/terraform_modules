locals {
  availability_zone = data.aws_availability_zones.available.names[0]
  subnet_cidrs = {
    workload = cidrsubnet(var.vpc_cidr, 8, 10)
    firewall = cidrsubnet(var.vpc_cidr, 8, 20)
    transit  = cidrsubnet(var.vpc_cidr, 8, 30)
  }
  default_tags = merge(
    {
      org_it_cost_center       = var.org_it_cost_center
      org_department           = var.org_department
      org_cmdb_calculated_app  = var.org_cmdb_calculated_app
      org_business_criticality = var.org_business_criticality
      org_environment          = var.org_environment
      org_data_classification  = var.org_data_classification

      Project   = var.project_name
      ManagedBy = "Terraform"
    },
    var.additional_tags
  )
  firewall_policies = {
    inspection = {
      name        = "module-test-network-firewall-routing-policy"
      description = "Minimal policy supporting the Network Firewall routing module test."
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
