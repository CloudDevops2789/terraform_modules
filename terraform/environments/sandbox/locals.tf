locals {
  

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  # Applied to the majority of resources created by the environment. Individual
  # modules may merge additional tags (for example Name) on top of these.
  default_tags = {
    Environment = "Sandbox"
    Project     = "AWS-IRE"
    Owner       = "CloudEngineering"
    ManagedBy   = "Terraform"
  }

  ##################################################################################################
  # Recovery Access VPC
  ##################################################################################################
  # Static network definition for the Recovery Access tier. This VPC is the
  # administrative entry point into the IRE and is intentionally allocated the
  # 10.100.0.0/16 address space. These values define the environment's network
  # architecture rather than deployment-time configuration.
  recovery_access = {
    vpc_name                 = "recovery-access"
    cidr_block               = "10.100.0.0/16"
    availability_zone_count  = 2

    private_subnets = {
      private-a = "10.100.11.0/24"
      private-b = "10.100.12.0/24"
    }
  }

  ##################################################################################################
  # Core Recovery VPC
  ##################################################################################################
  # Static network definition for the Core Recovery tier. This VPC hosts the
  # recovery tooling and acts as the central routing domain between Recovery
  # Access and Protected Data.
  core_recovery = {
    vpc_name                 = "core-recovery"
    cidr_block               = "10.101.0.0/16"
    availability_zone_count  = 2

    private_subnets = {
      private-a = "10.101.11.0/24"
      private-b = "10.101.12.0/24"
    }
  }

  ##################################################################################################
  # Protected Data VPC
  ##################################################################################################
  # Static network definition for the Protected Data tier. This VPC contains
  # backup storage and recovery data and is isolated from direct access by the
  # Recovery Access VPC through Transit Gateway routing.
  protected_data = {
    vpc_name                 = "protected-data"
    cidr_block               = "10.102.0.0/16"
    availability_zone_count  = 2

    private_subnets = {
      private-a = "10.102.11.0/24"
      private-b = "10.102.12.0/24"
    }
  }
    ##################################################################################################
  # Transit Gateway
  ##################################################################################################
  # Static configuration for the Transit Gateway. This defines the gateway
  # itself and the Transit Gateway Route Tables that represent the routing
  # domains within the IRE.
  #
  # NOTE:
  # The map keys (recovery_access, core_recovery, protected_data) are logical
  # Terraform identifiers. These keys are later referenced by the VPC
  # attachments to associate with the correct Transit Gateway Route Table.
  #
  # The 'name' attribute is simply the display name shown in the AWS Console.
  transit_gateway = {

    name = "ire-transit-gateway"

    default_route_table_association = "disable"
    default_route_table_propagation = "disable"

    route_tables = {

      recovery_access = {
        name = "Recovery Access Route Table"
      }

      core_recovery = {
        name = "Core Recovery Route Table"
      }

      protected_data = {
        name = "Protected Data Route Table"
      }

    }

  }
}
