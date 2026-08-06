##################################################################################################
# Compute
##################################################################################################

module "key_pair" {
  source = "../../modules/key-pair"

  key_pairs = {
    management = {
      public_key = file(var.public_key_path)
    }
  }

  tags = local.org_tags
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = local.ec2.ami_data_source_filter.name_values
  }

  filter {
    name   = "architecture"
    values = local.ec2.ami_data_source_filter.architecture_values
  }

  filter {
    name   = "virtualization-type"
    values = local.ec2.ami_data_source_filter.virtualization_type_values
  }
}

module "ec2" {
  source = "../../modules/ec2"

  instances = {
    management = {
      ami                         = local.ec2.ami
      instance_type               = local.ec2.instance_type
      subnet_id                   = module.recovery_access.subnet_ids["admin-tools-b"]
      associate_public_ip_address = false
      key_name                    = module.key_pair.key_names["management"]
      vpc_security_group_ids = [
        module.security_group.security_group_ids["management"],
      ]
    }

    core = {
      ami                         = local.ec2.ami
      instance_type               = local.ec2.instance_type
      subnet_id                   = module.core_recovery.subnet_ids["recovery-services-a"]
      associate_public_ip_address = false
      key_name                    = module.key_pair.key_names["management"]
      vpc_security_group_ids = [
        module.security_group.security_group_ids["core"],
      ]
    }

    protected = {
      ami                         = local.ec2.ami
      instance_type               = local.ec2.instance_type
      subnet_id                   = module.protected_data.subnet_ids["protected-workloads-a"]
      associate_public_ip_address = false
      key_name                    = module.key_pair.key_names["management"]
      vpc_security_group_ids = [
        module.security_group.security_group_ids["protected"],
      ]
    }
  }

  tags = local.org_tags
}
