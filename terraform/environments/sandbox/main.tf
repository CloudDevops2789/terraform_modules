# This file is the ROOT MODULE of the sandbox environment. Terraform starts
# evaluating here. It contains no resources of its own - instead it composes
# reusable child modules (vpc, transit-gateway) into the 3-VPC IRE topology:
# Landing Zone -> Core Recovery -> Protected Data, joined by a Transit Gateway.

########################################################
# Networking
########################################################

############################################
# Recovery Access VPC
############################################
# Entry point for administrators before they reach recovery workloads.
# This is the only VPC in the topology that would host public subnets
# in a production layout (disabled here for the sandbox). All traffic
# into the IRE is expected to land here first, then hop to Core Recovery
# over the Transit Gateway per the trust model below.
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
# Hosts the recovery tooling and compute tier, and acts as the central
# routing domain within the IRE. No public_subnets input is given, so
# the module falls back to its default of {} and creates no public
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
# Holds the immutable backup data - the most sensitive tier in the IRE.
# Private subnets only, same isolation pattern as Core Recovery. Direct
# routing to Recovery Access is intentionally omitted below so that
# administrators can never reach protected data without transiting
# Core Recovery first.
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

############################################
# Transit Gateway
############################################
# The Transit Gateway is the central router connecting all three VPCs
# and is the mechanism that enforces the IRE trust chain: Recovery
# Access <-> Core Recovery <-> Protected Data, with no direct path
# between Recovery Access and Protected Data. Route table association
# and propagation are handled per-attachment below rather than through
# the TGW default route table, which is why default association and
# propagation are disabled.
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

########################################################
# Security
########################################################

############################################
# Security Groups
############################################
# One security group per trust tier (management, core, protected).
# Grouping rules by tier - rather than by instance - keeps the security
# posture legible: each tier's allowed traffic maps directly to the
# IRE trust chain enforced by the Transit Gateway route tables above.
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

############################################
# Security Group Rules
############################################
# Ingress/egress rules for each tier's security group. Ingress is scoped
# to the CIDR of the adjacent, trusted VPC only (e.g. Protected Data only
# accepts SSH from Core Recovery), mirroring the no-direct-path rule
# enforced at the network layer. Management is the exception, since it is
# the administrator entry point and is reachable from 0.0.0.0/0 in this
# sandbox configuration.
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

########################################################
# Compute
########################################################

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

##################################################################################################
# Recovery
##################################################################################################

# The Recovery modules implement the AWS
# Backup architecture for the Isolated
# Recovery Environment (IRE).
#
# Together they provide backup storage,
# backup scheduling, workload selection,
# backup permissions, and immutable copies
# of recovery points for cyber recovery.

############################################
# Standard Backup Vault
############################################
# Creates the primary AWS Backup Vault used
# to store recovery points generated by
# AWS Backup jobs.
#
# Recovery points stored in this vault can
# later be copied to a Logically Air-Gapped
# Vault for ransomware protection.
module "backup_standard_vault" {

  source = "../../modules/backup-standard-vault"

  name = "ire-standard-backup-vault"

  tags = local.default_tags

}

############################################
# Logically Air-Gapped Backup Vault
############################################
# Creates an AWS Backup Logically Air-Gapped
# Vault used to store immutable copies of
# recovery points.
#
# This vault provides an additional layer of
# protection against ransomware, accidental
# deletion, and credential compromise.
module "backup_logically_air_gapped_vault" {

  source = "../../modules/backup-logically-air-gapped-vault"

  name = "ire-airgap-backup-vault"

  min_retention_days = 30

  max_retention_days = 365

  tags = local.default_tags

}

############################################
# Backup Plan
############################################

# Defines how AWS Backup protects the
# recovery environment.
#
# The Backup Plan determines when backups
# are created, how long they are retained,
# and whether recovery points are copied
# to additional Backup Vaults for
# cyber recovery.
module "backup_plan" {

  source = "../../modules/backup-plan"

  name = "ire-backup-plan"

  backup_vault_name = module.backup_standard_vault.name

  rules = {

    daily = {

      schedule = "cron(0 5 ? * * *)"

      start_window = 60

      completion_window = 180

      lifecycle = {

        cold_storage_after = 30

        delete_after = 365

      }

      copy_actions = {

      cyber_recovery = {

        destination_vault_arn = module.backup_logically_air_gapped_vault.arn

        lifecycle = {

          delete_after = 365

        }

      }

    }

    }

  }

  tags = local.default_tags

}

############################################
# Backup IAM Role
############################################

# Creates the IAM Role assumed by AWS Backup
# to perform backup and restore operations.
#
# The role includes the required trust
# relationship and managed IAM policies
# that allow AWS Backup to protect and
# recover supported AWS resources.
#
module "backup_role" {

  source = "../../modules/backup-role"

  name = "ire-backup-role"

  tags = local.default_tags

}

############################################
# Backup Selection
############################################

# Associates AWS resources with the
# Backup Plan.
#
# Only resources included in this
# selection are protected by AWS Backup.
# In this environment, the Core Recovery
# EC2 instance is designated as the
# protected workload.
module "backup_selection" {

  source = "../../modules/backup-selection"

  name = "ire-backup-selection"

  backup_plan_id = module.backup_plan.id

  iam_role_arn = module.backup_role.arn

  resources = [

    module.ec2.instance_arns["core"] # associate the core instance with the backup plan

  ]

  tags = local.default_tags

}

########################################################
# Remote Access
########################################################

############################################
# Client VPN
############################################
# Provides administrator remote access into the Recovery Access VPC,
# the designated entry point for the IRE. Authorization is currently
# all-groups via certificate auth; the commented block below documents
# the planned extension point for group-scoped access once IAM Identity
# Center (SAML) is introduced as the auth source - at that point the
# interface here barely changes, it just gains an optional group
# identifier per authorization rule.
module "client_vpn" {

  source = "../../modules/client-vpn"

  name = "ire-client-vpn"

  #server_certificate_arn     = "arn:aws:acm:us-east-1:781436988948:certificate/5bf9218b-6fbc-4cb3-a02b-0eb291d771b5"
  #root_certificate_chain_arn = "arn:aws:acm:us-east-1:781436988948:certificate/fc51c80f-aa8a-4830-ad23-5a3f42ffd26f"
  server_certificate_arn     = var.server_certificate_arn
  root_certificate_chain_arn = var.root_certificate_chain_arn

  client_cidr_block = "192.168.0.0/16"

  vpc_id = module.recovery_access.vpc_id

  network_associations = {

    az1 = {
      subnet_id = module.recovery_access.private_subnet_ids[0]
    }

    az2 = {
      subnet_id = module.recovery_access.private_subnet_ids[1]
    }

  }

  security_group_ids = [
    module.security_group.security_group_ids["management"]
  ]

  split_tunnel       = true
  transport_protocol = "udp"
  vpn_port           = 443
  dns_servers        = []

  session_timeout_hours = 8

  authorization_rules = {
    #When we  move to IAM Identity Center (SAML), your interface barely changes.  
    #you could extend the object with an optional group identifier 
    #access_group_id = "cloud-admin"
    recovery_access = {

      target_network_cidr = module.recovery_access.vpc_cidr

      authorize_all_groups = true

    }

  }

  routes = {}

}
