##################################################################################################
# Compute
##################################################################################################

############################################
# Key Pair
############################################
# Single management key pair used to reach instances across all three
# tiers via SSH. Centralizing on one key keeps break-glass access simple
# in the sandbox; production environments would typically scope keys
# per tier or replace this with Systems Manager Session Manager.
module "key_pair" {

  source = "../../modules/key-pair"

  tags = local.org_tags
  key_pairs = {
    management = {
      public_key = file(var.public_key_path)
    }
  }

}

############################################
# AMI Data Source
############################################
# Resolves the latest Amazon Linux 2023 (x86_64, HVM) AMI at apply time.
# Currently unused by the EC2 module below, which pins explicit AMI IDs
# instead so that sandbox builds are reproducible; retained here as the
# supported path for moving to dynamically resolved AMIs later.
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

############################################
# EC2
############################################
# One representative instance per tier (management, core, protected) to
# validate connectivity and routing across the IRE topology. All three
# sit on private subnets with no public IPs, consistent with the
# sandbox's no-public-subnet posture.
module "ec2" {

  source = "../../modules/ec2"

  tags = local.org_tags
  instances = {

    management = {
      ami           = local.ec2.ami
      instance_type = local.ec2.instance_type

      subnet_id                   = module.recovery_access.private_subnet_ids[1] # create on 2nd subnet and changed to private subnet to avoid public IPs in sandbox
      associate_public_ip_address = local.ec2.associate_public_ip_address        # true when we want public IPs on instances in this subnet

      key_name = module.key_pair.key_names["management"]

      vpc_security_group_ids = [
        module.security_group.security_group_ids["management"]
      ]
    }

    core = {
      #ami           = data.aws_ami.amazon_linux.id
      ami           = local.ec2.ami
      instance_type = local.ec2.instance_type

      subnet_id = module.core_recovery.private_subnet_ids[0]

      key_name = module.key_pair.key_names["management"]

      vpc_security_group_ids = [
        module.security_group.security_group_ids["core"]
      ]
    }

    protected = {
      #ami           = data.aws_ami.amazon_linux.id
      ami           = local.ec2.ami
      instance_type = local.ec2.instance_type

      subnet_id = module.protected_data.private_subnet_ids[0]

      key_name = module.key_pair.key_names["management"]

      vpc_security_group_ids = [
        module.security_group.security_group_ids["protected"]
      ]
    }

  }

}
