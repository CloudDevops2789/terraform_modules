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

  ##################################################################################################
  # KMS
  ##################################################################################################
  # Static configuration for the customer managed KMS key used across the
  # sandbox.
  kms = {
    description = "Customer managed KMS key for the ${var.naming.project_display_name} ${var.naming.environment}"
    alias       = local.resource_names.general_kms_alias
  }
}
