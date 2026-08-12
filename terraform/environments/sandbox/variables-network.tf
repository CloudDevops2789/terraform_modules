##################################################################################################
# Network Architecture Variables
##################################################################################################

variable "network_config" {
  description = "Environment-specific IRE VPC, subnet, and Client VPN CIDR allocation."

  type = object({
    account_cidr_block    = string
    client_vpn_cidr_block = string

    vpcs = object({
      recovery_access = object({
        cidr_block = string
        subnet_cidrs = object({
          client_vpn_a      = string
          client_vpn_b      = string
          admin_tools_a     = string
          admin_tools_b     = string
          endpoints_a       = string
          endpoints_b       = string
          transit_gateway_a = string
          transit_gateway_b = string
        })
      })

      core_recovery = object({
        cidr_block = string
        subnet_cidrs = object({
          recovery_services_a  = string
          recovery_services_b  = string
          directory_services_a = string
          directory_services_b = string
          endpoints_a          = string
          endpoints_b          = string
          transit_gateway_a    = string
          transit_gateway_b    = string
        })
      })

      protected_data = object({
        cidr_block = string
        subnet_cidrs = object({
          protected_workloads_a = string
          protected_workloads_b = string
          ingestion_a           = string
          ingestion_b           = string
          database_a            = string
          database_b            = string
          file_services_a       = string
          file_services_b       = string
          endpoints_a           = string
          endpoints_b           = string
          transit_gateway_a     = string
          transit_gateway_b     = string
        })
      })

      inspection = object({
        cidr_block = string
        subnet_cidrs = object({
          firewall_a        = string
          firewall_b        = string
          transit_gateway_a = string
          transit_gateway_b = string
        })
      })
    })
  })

  nullable = false

  validation {
    condition = alltrue([
      for cidr in concat(
        [
          var.network_config.account_cidr_block,
          var.network_config.client_vpn_cidr_block,
          var.network_config.vpcs.recovery_access.cidr_block,
          var.network_config.vpcs.core_recovery.cidr_block,
          var.network_config.vpcs.protected_data.cidr_block,
          var.network_config.vpcs.inspection.cidr_block,
        ],
        values(var.network_config.vpcs.recovery_access.subnet_cidrs),
        values(var.network_config.vpcs.core_recovery.subnet_cidrs),
        values(var.network_config.vpcs.protected_data.subnet_cidrs),
        values(var.network_config.vpcs.inspection.subnet_cidrs),
      ) : can(cidrhost(cidr, 0))
    ])

    error_message = "Every network_config address must be a valid CIDR block."
  }
}

#### Variable to Bypass network firewall

variable "network_inspection_mode" {
  description = "Network inspection mode. 'firewall' routes approved inter-VPC traffic through AWS Network Firewall; 'bypass' routes approved traffic directly through Transit Gateway."
  type        = string
  default     = "firewall"

  validation {
    condition = contains(
      ["firewall", "bypass"],
      var.network_inspection_mode
    )

    error_message = "network_inspection_mode must be either 'firewall' or 'bypass'."
  }
}

################################################################################
# Security Group Policy
################################################################################
