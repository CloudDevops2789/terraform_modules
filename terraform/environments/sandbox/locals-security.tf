locals {
  ##################################################################################################
  # Security Groups
  ##################################################################################################
  # Static configuration for the per-tier security groups and their
  # ingress/egress rules. Descriptions and rule protocols/ports are deployment
  # configuration. security_group_id values and any CIDR that references a
  # peer VPC (e.g. module.recovery_access.vpc_cidr) are infrastructure
  # relationships and remain directly in security.tf.
  security_groups = {

    tiers = {
      management = {
        description = "Management"
      }
      core = {
        description = "Core Recovery"
      }
      protected = {
        description = "Protected Data"
      }
    }
  }

}
