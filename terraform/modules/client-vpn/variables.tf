############################################
# Client VPN Endpoint
############################################

# Human-readable name for the Client VPN endpoint.
#
# This is used for tagging and resource naming so the endpoint is
# easily identifiable in the AWS Console.
variable "name" {
  description = "Name of the Client VPN endpoint."
  type        = string
}

# CIDR block from which VPN clients receive an IP address after
# successfully connecting.
#
# AWS requires:
# - Between /12 and /22
# - Must NOT overlap with any VPC CIDR
# - Must NOT overlap with on-premises networks
#
# Example:
# 192.168.0.0/16
variable "client_cidr_block" {

  description = "CIDR block assigned to VPN clients."

  type = string

  validation {

    condition = can(cidrhost(var.client_cidr_block, 0))

    error_message = "client_cidr_block must be a valid IPv4 CIDR block."

  }

}

# Authentication method used by the Client VPN endpoint.
#
# Supported values:
# - certificate: Mutual Authentication using client certificates.
# - federated: Federated Authentication using SAML 2.0.
variable "authentication_type" {
  description = "Client VPN authentication method. Supported values are certificate and federated."
  type        = string
  default     = "certificate"

  validation {
    condition = contains([
      "certificate",
      "federated"
    ], var.authentication_type)

    error_message = "authentication_type must be either certificate or federated."
  }
}

############################################
# Certificates
############################################

# ACM certificate presented by the VPN endpoint during the TLS handshake.
#
# The certificate must exist in ACM before this module is deployed.
#
# This module intentionally accepts the ARN instead of creating the
# certificate itself. That keeps certificate lifecycle management
# separate from VPN infrastructure.
variable "server_certificate_arn" {
  description = "ARN of the ACM server certificate."
  type        = string
}

# ACM Certificate Authority used to validate client certificates.
#
# When Mutual Authentication is enabled, AWS validates every client
# certificate against this trusted CA.
#
# Normally this is the ARN of the imported EasyRSA CA certificate.
variable "root_certificate_chain_arn" {
  description = "ARN of the ACM root certificate chain. Required when authentication_type is certificate."
  type        = string
  default     = null
  nullable    = true
}

# ARN of the IAM SAML identity provider used for federated authentication.
# This is required when authentication_type is federated.
variable "saml_provider_arn" {
  description = "ARN of the IAM SAML identity provider. Required when authentication_type is federated."
  type        = string
  default     = null
  nullable    = true
}

############################################
# VPN Configuration
############################################

# Determines whether VPN clients send ALL traffic through AWS or only
# traffic destined for AWS networks.
#
# true  = Split Tunnel (recommended)
# false = Full Tunnel
#
# Split Tunnel is preferred for enterprise environments because
# Internet traffic continues to use the client's local gateway while
# only AWS-bound traffic traverses the VPN.
variable "split_tunnel" {
  description = "Enable split tunnel."
  type        = bool
  default     = true
}

# Transport protocol used by the VPN endpoint.
#
# UDP provides better performance and is AWS's recommended default.
#
# TCP may be useful when restrictive firewalls block UDP traffic.
variable "transport_protocol" {

  description = "Transport protocol used by the Client VPN endpoint."

  type = string

  default = "udp"

  validation {

    condition = contains(
      ["udp", "tcp"],
      lower(var.transport_protocol)
    )

    error_message = "transport_protocol must be either 'udp' or 'tcp'."

  }

}
# Port on which the VPN endpoint listens.
#
# The default (443) works well because it is commonly allowed through
# enterprise firewalls.
variable "vpn_port" {

  description = "Port used by the Client VPN endpoint."

  type = number

  default = 443

  validation {

    condition = contains(
      [443, 1194],
      var.vpn_port
    )

    error_message = "vpn_port must be either 443 or 1194."

  }

}

############################################
# Networking
############################################

# Recovery Access VPC where the Client VPN endpoint will be deployed.
#
# AWS creates Elastic Network Interfaces (ENIs) inside associated
# subnets within this VPC.
variable "vpc_id" {
  description = "ID of the VPC containing the Client VPN target networks."

  type = string
}

# Security groups attached to the Client VPN endpoint.
#
# These control traffic entering and leaving the endpoint ENIs.
#
# Multiple security groups may be attached.
variable "security_group_ids" {
  description = "Security groups attached to the VPN endpoint."
  type        = list(string)
}

# Optional DNS servers pushed to connected VPN clients.
#
# Leave empty to allow AWS to use the VPC DNS resolver.
variable "dns_servers" {
  description = "Optional DNS servers."
  type        = list(string)
  default     = []
}

############################################
# Session Management
############################################

# Maximum amount of time a VPN session may remain connected before
# requiring re-authentication.
#
# Valid values:
# 8, 10, 12, or 24 hours
variable "session_timeout_hours" {

  description = "Maximum VPN session duration."

  type = number

  default = 8

  validation {

    condition = contains(
      [8, 10, 12, 24],
      var.session_timeout_hours
    )

    error_message = "session_timeout_hours must be one of 8, 10, 12, or 24."

  }

}

############################################
# Connection Logging
############################################

# Enable or disable Client VPN connection logging.
#
# Logging is recommended for production because it records
# connection attempts, authentication failures and session events.
variable "enable_connection_logging" {
  description = "Enable CloudWatch connection logging."
  type        = bool
  default     = true
}

# Number of days CloudWatch logs should be retained.
#
# Setting a retention period prevents logs from growing
# indefinitely and helps control CloudWatch costs.
variable "log_retention_in_days" {

  description = "Retention period for CloudWatch logs."

  type = number

  default = 30

  validation {

    condition = contains(
      [
        1,
        3,
        5,
        7,
        14,
        30,
        60,
        90,
        120,
        150,
        180,
        365,
        400,
        545,
        731,
        1096,
        1827,
        2192,
        2557,
        2922,
        3288,
        3653
      ],
      var.log_retention_in_days
    )

    error_message = "Invalid CloudWatch log retention period."

  }

}

############################################
# Tags
############################################

# Additional resource tags supplied by the root module.
#
# These are merged with module-specific tags to provide consistent
# tagging across the AWS environment.
variable "tags" {
  description = "Tags applied to resources."
  type        = map(string)
  default     = {}
}

############################################
# Target Network Associations
############################################

# List of subnet IDs where the Client VPN endpoint will create
# network associations.
#
# AWS creates an Elastic Network Interface (ENI) in each associated
# subnet, allowing VPN clients to enter the VPC.
#
# A minimum of one subnet is required.
#
# Multiple subnets improve availability by allowing clients to
# connect through different Availability Zones.
variable "network_associations" {

  description = "Subnets associated with the Client VPN endpoint."

  type = map(object({
    subnet_id = string
  }))

  default = {}
}

############################################
# Authorization Rules
############################################

# Authorization rules determine which destination networks
# authenticated VPN clients are permitted to access.
#
# Each map entry creates one Client VPN authorization rule.
#
# Example:
#
# authorization_rules = {
#
#   recovery_access = {
#     target_network_cidr = "10.100.0.0/16"
#     authorize_all_groups = true
#   }
#
#   core_recovery = {
#     target_network_cidr = "10.101.0.0/16"
#     authorize_all_groups = true
#   }
#
# }
#
variable "authorization_rules" {

  description = "Authorization rules for the Client VPN endpoint."

  type = map(object({

    target_network_cidr = string

    authorize_all_groups = optional(bool, true)

  }))

  default = {}

}

############################################
# Client VPN Routes
############################################

# Destination networks reachable through the Client VPN.
#
# Each route tells the VPN endpoint how to reach a destination
# network after a client has successfully connected.
#
# AWS requires every route to specify:
#
# - Destination CIDR
# - Target subnet association
#
# Example:
#
# 10.100.0.0/16 → Recovery Access
# 10.101.0.0/16 → Core Recovery
# 10.102.0.0/16 → Protected Data
#
variable "routes" {

  description = "Client VPN routes."

  type = map(object({

    destination_cidr_block = string

    target_subnet_id = string

    description = optional(string)

  }))

  default = {}
}