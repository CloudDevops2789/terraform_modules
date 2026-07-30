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

  default_tags = local.default_tags

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
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
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

  default_tags = local.default_tags

  instances = {

    management = {
      ami           = "ami-00adf8f2fe708c532" # Amazon Linux 2023 (x86_64) - us-east-1
      instance_type = "t3.micro"

      subnet_id                   = module.recovery_access.private_subnet_ids[1] # create on 2nd subnet and changed to private subnet to avoid public IPs in sandbox
      associate_public_ip_address = false                                        # true when we want public IPs on instances in this subnet

      key_name = module.key_pair.key_names["management"]

      vpc_security_group_ids = [
        module.security_group.security_group_ids["management"]
      ]
    }

    core = {
      #ami           = data.aws_ami.amazon_linux.id
      ami           = "ami-00adf8f2fe708c532" # Amazon Linux 2023 (x86_64) - us-east-1
      instance_type = "t3.micro"

      subnet_id = module.core_recovery.private_subnet_ids[0]

      key_name = module.key_pair.key_names["management"]

      vpc_security_group_ids = [
        module.security_group.security_group_ids["core"]
      ]
    }

    protected = {
      #ami           = data.aws_ami.amazon_linux.id
      ami           = "ami-00adf8f2fe708c532" # Amazon Linux 2023 (x86_64) - us-east-1 
      instance_type = "t3.micro"

      subnet_id = module.protected_data.private_subnet_ids[0]

      key_name = module.key_pair.key_names["management"]

      vpc_security_group_ids = [
        module.security_group.security_group_ids["protected"]
      ]
    }

  }

}
