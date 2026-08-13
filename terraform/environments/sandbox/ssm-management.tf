##################################################################################################
# Persistent Systems Manager Management Plane
##################################################################################################

data "aws_partition" "ssm" {}

locals {
  ssm_managed_compute_name = join(
    "-",
    compact([
      var.naming.organization,
      var.naming.project,
      var.naming.environment,
      var.naming.region_code,
      "ssm-managed-compute"
    ])
  )

  effective_ssm_instance_profile_name = (
    var.ssm_instance_profile_mode == "external"
    ? var.ssm_instance_profile_name
    : try(module.ssm_iam[0].instance_profile_names["managed_compute"], null)
  )

  ssm_endpoint_security_group_rules = var.ssm_management_plane_enabled ? {
    ssm-recovery-access-https = {
      type                         = "ingress"
      description                  = "HTTPS from Recovery Access to private Systems Manager endpoints"
      security_group_id            = module.security_group.security_group_ids["ssm_recovery_access"]
      ip_protocol                  = "tcp"
      from_port                    = 443
      to_port                      = 443
      cidr_ipv4                    = null
      referenced_security_group_id = module.security_group.security_group_ids["management"]
    }

    ssm-core-recovery-https = {
      type                         = "ingress"
      description                  = "HTTPS from Core Recovery to private Systems Manager endpoints"
      security_group_id            = module.security_group.security_group_ids["ssm_core_recovery"]
      ip_protocol                  = "tcp"
      from_port                    = 443
      to_port                      = 443
      cidr_ipv4                    = null
      referenced_security_group_id = module.security_group.security_group_ids["core"]
    }

    ssm-protected-data-https = {
      type                         = "ingress"
      description                  = "HTTPS from Protected Data to private Systems Manager endpoints"
      security_group_id            = module.security_group.security_group_ids["ssm_protected_data"]
      ip_protocol                  = "tcp"
      from_port                    = 443
      to_port                      = 443
      cidr_ipv4                    = null
      referenced_security_group_id = module.security_group.security_group_ids["protected"]
    }
  } : {}
}

##################################################################################################
# Optional Terraform-managed IAM
##################################################################################################

module "ssm_iam" {
  count = (
    var.ssm_management_plane_enabled &&
    var.ssm_instance_profile_mode == "terraform"
  ) ? 1 : 0

  source = "../../modules/iam"

  roles = {
    managed_compute = {
      name                    = local.ssm_managed_compute_name
      instance_profile_name   = local.ssm_managed_compute_name
      create_instance_profile = true

      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Service = "ec2.amazonaws.com"
            }
            Action = "sts:AssumeRole"
          }
        ]
      })

      managed_policy_arns = [
        "arn:${data.aws_partition.ssm.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
    }
  }

  tags = local.org_tags
}

##################################################################################################
# Recovery Access - Systems Manager Endpoints
##################################################################################################

module "recovery_access_ssm_endpoints" {
  count  = var.ssm_management_plane_enabled ? 1 : 0
  source = "../../modules/vpc-endpoints"

  vpc_id = module.recovery_access.vpc_id

  interface_endpoints = {
    ssm = {
      service_name = "com.amazonaws.${var.aws_region}.ssm"

      subnet_ids = [
        module.recovery_access.subnet_ids["endpoints-a"],
        module.recovery_access.subnet_ids["endpoints-b"]
      ]

      security_group_ids = [
        module.security_group.security_group_ids["ssm_recovery_access"]
      ]

      private_dns_enabled = true
    }

    ssmmessages = {
      service_name = "com.amazonaws.${var.aws_region}.ssmmessages"

      subnet_ids = [
        module.recovery_access.subnet_ids["endpoints-a"],
        module.recovery_access.subnet_ids["endpoints-b"]
      ]

      security_group_ids = [
        module.security_group.security_group_ids["ssm_recovery_access"]
      ]

      private_dns_enabled = true
    }
  }

  tags = local.org_tags
}

##################################################################################################
# Core Recovery - Systems Manager Endpoints
##################################################################################################

module "core_recovery_ssm_endpoints" {
  count  = var.ssm_management_plane_enabled ? 1 : 0
  source = "../../modules/vpc-endpoints"

  vpc_id = module.core_recovery.vpc_id

  interface_endpoints = {
    ssm = {
      service_name = "com.amazonaws.${var.aws_region}.ssm"

      subnet_ids = [
        module.core_recovery.subnet_ids["endpoints-a"],
        module.core_recovery.subnet_ids["endpoints-b"]
      ]

      security_group_ids = [
        module.security_group.security_group_ids["ssm_core_recovery"]
      ]

      private_dns_enabled = true
    }

    ssmmessages = {
      service_name = "com.amazonaws.${var.aws_region}.ssmmessages"

      subnet_ids = [
        module.core_recovery.subnet_ids["endpoints-a"],
        module.core_recovery.subnet_ids["endpoints-b"]
      ]

      security_group_ids = [
        module.security_group.security_group_ids["ssm_core_recovery"]
      ]

      private_dns_enabled = true
    }
  }

  tags = local.org_tags
}

##################################################################################################
# Protected Data - Systems Manager Endpoints
##################################################################################################

module "protected_data_ssm_endpoints" {
  count  = var.ssm_management_plane_enabled ? 1 : 0
  source = "../../modules/vpc-endpoints"

  vpc_id = module.protected_data.vpc_id

  interface_endpoints = {
    ssm = {
      service_name = "com.amazonaws.${var.aws_region}.ssm"

      subnet_ids = [
        module.protected_data.subnet_ids["endpoints-a"],
        module.protected_data.subnet_ids["endpoints-b"]
      ]

      security_group_ids = [
        module.security_group.security_group_ids["ssm_protected_data"]
      ]

      private_dns_enabled = true
    }

    ssmmessages = {
      service_name = "com.amazonaws.${var.aws_region}.ssmmessages"

      subnet_ids = [
        module.protected_data.subnet_ids["endpoints-a"],
        module.protected_data.subnet_ids["endpoints-b"]
      ]

      security_group_ids = [
        module.security_group.security_group_ids["ssm_protected_data"]
      ]

      private_dns_enabled = true
    }
  }

  tags = local.org_tags
}
