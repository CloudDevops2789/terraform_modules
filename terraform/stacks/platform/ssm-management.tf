##################################################################################################
# Generic Systems Manager Management Plane
##################################################################################################

data "aws_partition" "ssm" {}

locals {
  ssm_managed_compute_name = join(
    "-",
    compact([
      var.naming.organization,
      var.naming.project,
      var.naming.environment,
      local.effective_region_code,
      "ssm-managed-compute"
    ])
  )

  effective_ssm_instance_profile_name = (
    var.ssm_instance_profile_mode == "external"
    ? var.ssm_instance_profile_name
    : try(
      module.ssm_iam[0].instance_profile_names["managed_compute"],
      null
    )
  )

  ssm_endpoint_security_group_definitions = (
    var.ssm_management_plane_enabled
    ? {
      for vpc_key, binding in var.ssm_endpoint_bindings :
      "ssm_${vpc_key}" => {
        description = "Private Systems Manager endpoints for ${vpc_key}"
        vpc_id      = module.vpc[vpc_key].vpc_id
        tags        = {}
      }
    }
    : {}
  )

  ssm_endpoint_security_group_rules = (
    var.ssm_management_plane_enabled
    ? merge(
      {},
      [
        for vpc_key, binding in var.ssm_endpoint_bindings : {
          for source_security_group_key in binding.source_security_group_keys :
          "ssm-${replace(vpc_key, "_", "-")}-${replace(source_security_group_key, "_", "-")}-https" => {
            type        = "ingress"
            description = "HTTPS to private Systems Manager endpoints"

            security_group_id = (
              module.security_group.security_group_ids[
                "ssm_${vpc_key}"
              ]
            )

            ip_protocol = "tcp"
            from_port   = 443
            to_port     = 443

            cidr_ipv4 = null

            referenced_security_group_id = (
              module.security_group.security_group_ids[
                source_security_group_key
              ]
            )
          }
        }
      ]...
    )
    : {}
  )
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
# Generic Private SSM Endpoints
##################################################################################################

module "ssm_endpoints" {
  for_each = (
    var.ssm_management_plane_enabled
    ? var.ssm_endpoint_bindings
    : {}
  )

  source = "../../modules/vpc-endpoints"

  vpc_id = module.vpc[each.key].vpc_id

  interface_endpoints = {
    ssm = {
      service_name = "com.amazonaws.${var.aws_region}.ssm"

      subnet_ids = toset(
        module.vpc[
          each.key
        ].subnet_ids_by_group[each.value.subnet_group]
      )

      security_group_ids = toset([
        module.security_group.security_group_ids[
          "ssm_${each.key}"
        ]
      ])

      private_dns_enabled = true
    }

    ssmmessages = {
      service_name = "com.amazonaws.${var.aws_region}.ssmmessages"

      subnet_ids = toset(
        module.vpc[
          each.key
        ].subnet_ids_by_group[each.value.subnet_group]
      )

      security_group_ids = toset([
        module.security_group.security_group_ids[
          "ssm_${each.key}"
        ]
      ])

      private_dns_enabled = true
    }
  }

  tags = local.org_tags
}
