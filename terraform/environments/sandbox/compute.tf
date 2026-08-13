##################################################################################################
# Compute
##################################################################################################

# Purpose: Registers the supplied SSH public key only when demonstration EC2 instances are enabled.
# Change when: Change the public-key input when a different administrator or workstation is used.
module "key_pair" {
  source = "../../modules/key-pair"

  key_pairs = var.demo_ec2_enabled && var.demo_ec2_access_method == "ssh_key" ? {
    management = {
      public_key = file(var.public_key_path)
    }
  } : {}

  tags = local.org_tags
}

# Purpose: Optionally creates one representative EC2 instance in each active trust tier for traffic-flow validation.
# Change when: Change AMI, size, subnet placement, or security groups through environment inputs.
module "ec2" {
  source = "../../modules/ec2"

  instances = var.demo_ec2_enabled ? {
    management = {
      ami                         = local.ec2.ami
      instance_type               = local.ec2.instance_type
      subnet_id                   = module.recovery_access.subnet_ids["admin-tools-b"]
      associate_public_ip_address = false
      key_name                    = var.demo_ec2_access_method == "ssh_key" ? module.key_pair.key_names["management"] : null
      iam_instance_profile        = var.demo_ec2_access_method == "ssm" ? local.effective_ssm_instance_profile_name : null
      vpc_security_group_ids = [
        module.security_group.security_group_ids["management"],
      ]
    }

    core = {
      ami                         = local.ec2.ami
      instance_type               = local.ec2.instance_type
      subnet_id                   = module.core_recovery.subnet_ids["recovery-services-a"]
      associate_public_ip_address = false
      key_name                    = var.demo_ec2_access_method == "ssh_key" ? module.key_pair.key_names["management"] : null
      iam_instance_profile        = var.demo_ec2_access_method == "ssm" ? local.effective_ssm_instance_profile_name : null
      vpc_security_group_ids = [
        module.security_group.security_group_ids["core"],
      ]
    }

    protected = {
      ami                         = local.ec2.ami
      instance_type               = local.ec2.instance_type
      subnet_id                   = module.protected_data.subnet_ids["protected-workloads-a"]
      associate_public_ip_address = false
      key_name                    = var.demo_ec2_access_method == "ssh_key" ? module.key_pair.key_names["management"] : null
      iam_instance_profile        = var.demo_ec2_access_method == "ssm" ? local.effective_ssm_instance_profile_name : null
      vpc_security_group_ids = [
        module.security_group.security_group_ids["protected"],
      ]
    }
  } : {}

  tags = local.org_tags
}
