# This file is the ROOT MODULE of the sandbox environment. Terraform starts
# evaluating here. It contains no resources of its own - instead it composes
# reusable child modules (vpc, transit-gateway) into the 3-VPC IRE topology:
# Landing Zone -> Core Recovery -> Protected Data, joined by a Transit Gateway.
#
############################################
# Landing Zone VPC
############################################

# A "module" block instantiates a child module. `source` points at the local
# module directory; everything else is an INPUT passed to that module's
# variables.tf. Terraform copies of the same module (below) are fully
# independent - each gets its own state entries.
# This VPC is the entry point where administrators land before reaching
# recovery workloads. It is the only VPC with public subnets (sandbox-only).
module "recovery_access" {

  source = "../../modules/vpc"

  vpc_name                = "recovery-access"
  cidr_block              = "10.100.0.0/16"
  availability_zone_count = 2

  # public_subnets = {   blocking entire section for now, since we don't want public subnets in the sandbox
  #  public-a = "10.100.1.0/24"
  #  public-b = "10.100.2.0/24"
  #}

  private_subnets = {
    private-a = "10.100.11.0/24"
    private-b = "10.100.12.0/24"
  }
  # Install routes in the private route table for networks reachable via
  # the Transit Gateway. Under the IRE trust model, the Recovery Access VPC
  # communicates only with the Core Recovery VPC.
  #public_transit_gateway_routes = [
   # {
   #   destination_cidr_block = module.core_recovery.vpc_cidr
   #   transit_gateway_id     = module.transit_gateway.id
   # }
  #]

  private_transit_gateway_routes = [
    {
      destination_cidr_block = module.core_recovery.vpc_cidr
      transit_gateway_id     = module.transit_gateway.id
    }
  ]
}

############################################
# Core Recovery VPC
############################################

# Hosts the recovery tooling/compute tier. Note: no `public_subnets` input is
# given, so the module falls back to its default of {} and creates no public
# subnets, no Internet Gateway, and no public route table for this VPC.
module "core_recovery" {

  source = "../../modules/vpc"

  vpc_name                = "core-recovery"
  cidr_block              = "10.101.0.0/16"
  availability_zone_count = 2

  private_subnets = {
    private-a = "10.101.11.0/24"
    private-b = "10.101.12.0/24"
  }

  # Core Recovery acts as the central routing domain within the IRE. It
  # requires routes to both the Recovery Access and Protected Data VPCs.
  private_transit_gateway_routes = [
    {
      destination_cidr_block = module.recovery_access.vpc_cidr
      transit_gateway_id     = module.transit_gateway.id
    },
    {
      destination_cidr_block = module.protected_data.vpc_cidr
      transit_gateway_id     = module.transit_gateway.id
    }
  ]
}

############################################
# Protected Data VPC
############################################

# Holds the immutable backup data (most sensitive tier). Private subnets only,
# same pattern as core_recovery - isolation is the point of this VPC.
module "protected_data" {

  source = "../../modules/vpc"

  vpc_name                = "protected-data"
  cidr_block              = "10.102.0.0/16"
  availability_zone_count = 2

  private_subnets = {
    private-a = "10.102.11.0/24"
    private-b = "10.102.12.0/24"
  }

  # Install routes for the Core Recovery VPC only. Direct routing to the
  # Recovery Access VPC is intentionally omitted to enforce the IRE trust
  # model.
  private_transit_gateway_routes = [
    {
      destination_cidr_block = module.core_recovery.vpc_cidr
      transit_gateway_id     = module.transit_gateway.id
    }
  ]
}



module "security_group" {

  source = "../../modules/security-group"

  default_tags = local.default_tags

  security_groups = {

    management = {
      description = "Management"
      vpc_id      = module.recovery_access.vpc_id
    }

    core = {
      description = "Core Recovery"
      vpc_id      = module.core_recovery.vpc_id
    }

    protected = {
      description = "Protected Data"
      vpc_id      = module.protected_data.vpc_id
    }

  }

}

module "security_group_rule" {

  source = "../../modules/security-group-rule"

  rules = {

    management-ssh = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22

      cidr_ipv4 = "0.0.0.0/0"
    }

    management-ping = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = "icmp"
      from_port   = 8
      to_port     = -1

      cidr_ipv4 = "0.0.0.0/0"
    }

    management-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["management"]

      ip_protocol = "-1"

      cidr_ipv4 = "0.0.0.0/0"
    }

    core-ssh-from-recovery-access = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["core"]

      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22

      cidr_ipv4 = module.recovery_access.vpc_cidr
    }

    core-ssh-from-protected-data = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["core"]

      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22

      cidr_ipv4 = module.protected_data.vpc_cidr
    }

    core-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["core"]

      ip_protocol = "-1"

      cidr_ipv4 = "0.0.0.0/0"
    }

    protected-ssh = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["protected"]

      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22

      cidr_ipv4 = module.core_recovery.vpc_cidr
    }

    protected-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["protected"]

      ip_protocol = "-1"

      cidr_ipv4 = "0.0.0.0/0"
    }

  }

}

############################################
# Transit Gateway
############################################

# The Transit Gateway is the central router connecting all three VPCs.
# The references like `module.recovery_access.vpc_id` read OUTPUTS of the vpc
# module instances above. These references are also how Terraform builds its
# dependency graph: it knows the VPCs must exist before the TGW attachments.
module "transit_gateway" {

  source = "../../modules/transit-gateway"

  name = "ire-transit-gateway"

  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  # Transit Gateway route tables representing the routing domains within
  # the recovery environment. Attachments associate with these route tables
  # and propagate routes according to the configured trust model.
  route_tables = {

    recovery_access = {
      name = "Recovery Access"
    }

    core_recovery = {
      name = "Core Recovery"
    }

    protected_data = {
      name = "Protected Data"
    }

  }

  # A map(object) input: one entry per VPC to attach. Inside the module this map
  # is iterated with for_each, so each key (recovery_access, core_recovery, ...)
  # becomes a stable resource address like
  # aws_ec2_transit_gateway_vpc_attachment.this["recovery_access"].
  # Attachments are placed in the PRIVATE subnets - the TGW creates a network
  # interface in each subnet you list.
  vpc_attachments = {

    recovery_access = {
      vpc_id     = module.recovery_access.vpc_id
      subnet_ids = module.recovery_access.private_subnet_ids

      route_table = "recovery_access"

      propagate_to = [
        "core_recovery"
      ]
    }

    core_recovery = {
      vpc_id     = module.core_recovery.vpc_id
      subnet_ids = module.core_recovery.private_subnet_ids

      route_table = "core_recovery"

      propagate_to = [
        "recovery_access",
        "protected_data"
      ]
    }

    protected_data = {
      vpc_id     = module.protected_data.vpc_id
      subnet_ids = module.protected_data.private_subnet_ids

      route_table = "protected_data"

      propagate_to = [
        "core_recovery"
      ]
    }
  }

  # Merged onto the TGW resources by the module (see its locals.tf). These are
  # in addition to the provider-level default_tags defined in provider.tf.
  tags = {
    Name        = "ire-transit-gateway"
    Project     = "AWS-IRE"
    Environment = "Sandbox"
    ManagedBy   = "Terraform"
    Owner       = "CloudEngineering"
  }

}

module "key_pair" {

  source = "../../modules/key-pair"

  default_tags = local.default_tags

  key_pairs = {
    management = {
      public_key = file(var.public_key_path)
    }
  }

}

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

module "ec2" {

  source = "../../modules/ec2"

  default_tags = local.default_tags

  instances = {

    management = {
      ami           = "ami-00adf8f2fe708c532" # Amazon Linux 2023 (x86_64) - us-east-1
      instance_type = "t3.micro"

      subnet_id                   = module.recovery_access.private_subnet_ids[1] # create on 2nd subnet and changed to private subnet to avoid public IPs in sandbox
      associate_public_ip_address = false # true when we want public IPs on instances in this subnet

      key_name = module.key_pair.key_names["management"]

      vpc_security_group_ids = [
        module.security_group.security_group_ids["management"]
      ]
    }

    core = {
      ami           = data.aws_ami.amazon_linux.id
      instance_type = "t3.micro"

      subnet_id = module.core_recovery.private_subnet_ids[0]

      key_name = module.key_pair.key_names["management"]

      vpc_security_group_ids = [
        module.security_group.security_group_ids["core"]
      ]
    }

    protected = {
      ami           = data.aws_ami.amazon_linux.id
      instance_type = "t3.micro"

      subnet_id = module.protected_data.private_subnet_ids[0]

      key_name = module.key_pair.key_names["management"]

      vpc_security_group_ids = [
        module.security_group.security_group_ids["protected"]
      ]
    }

  }

}