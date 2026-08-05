locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  # Applied on top of the provider's default_tags so resources created by
  # this test are identifiable as throwaway module-validation infrastructure.
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
  # VPC Under Test
  ##################################################################################################
  # This is the ONLY thing this environment exists to validate: that the vpc
  # module accepts these inputs and successfully creates a VPC with a
  # private subnet, a private route table, and the association between them.
  #
  # A single private subnet is the minimum shape that exercises every
  # required code path in the module (VPC, subnet, route table,
  # association) without exercising the optional public-subnet / Internet
  # Gateway path, which is not needed to answer "does this module deploy?".
  vpc = {
    vpc_name                = "module-test-vpc"
    cidr_block              = "10.250.0.0/16"
    availability_zone_count = 2

    private_subnets = {
      private-a = "10.250.11.0/24"
    }
  }
}
