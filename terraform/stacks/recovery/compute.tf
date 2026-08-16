##################################################################################################
# Recovery Compute
##################################################################################################

module "key_pair" {
  source = "../../modules/key-pair"

  key_pairs = var.demo_ec2_enabled && var.demo_ec2_access_method == "ssh_key" ? {
    management = {
      public_key = file(var.public_key_path)
    }
  } : {}

  tags = local.org_tags
}

module "ec2" {
  source = "../../modules/ec2"

  instances = var.demo_ec2_enabled ? {
    management = {
      ami                         = local.ec2.ami
      instance_type               = local.ec2.instance_type
      subnet_id                   = try(var.platform_contract.recovery_access_admin_subnet_id, null)
      associate_public_ip_address = false
      key_name                    = var.demo_ec2_access_method == "ssh_key" ? module.key_pair.key_names["management"] : null
      iam_instance_profile        = var.demo_ec2_access_method == "ssm" ? try(var.platform_contract.ssm_instance_profile_name, null) : null

      vpc_security_group_ids = [
        try(var.platform_contract.management_security_group_id, null)
      ]
    }

    core = {
      ami                         = local.ec2.ami
      instance_type               = local.ec2.instance_type
      subnet_id                   = try(var.platform_contract.core_recovery_subnet_id, null)
      associate_public_ip_address = false
      key_name                    = var.demo_ec2_access_method == "ssh_key" ? module.key_pair.key_names["management"] : null
      iam_instance_profile        = var.demo_ec2_access_method == "ssm" ? try(var.platform_contract.ssm_instance_profile_name, null) : null

      vpc_security_group_ids = [
        try(var.platform_contract.core_security_group_id, null)
      ]
    }

    protected = {
      ami                         = local.ec2.ami
      instance_type               = local.ec2.instance_type
      subnet_id                   = try(var.platform_contract.protected_data_subnet_id, null)
      associate_public_ip_address = false
      key_name                    = var.demo_ec2_access_method == "ssh_key" ? module.key_pair.key_names["management"] : null
      iam_instance_profile        = var.demo_ec2_access_method == "ssm" ? try(var.platform_contract.ssm_instance_profile_name, null) : null

      vpc_security_group_ids = [
        try(var.platform_contract.protected_security_group_id, null)
      ]
    }
  } : {}

  tags = local.org_tags
}
