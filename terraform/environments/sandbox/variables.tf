variable "aws_region" {
  description = "AWS Region for this environment."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region must not be empty."
  }
}

variable "public_key_path" {
  description = "Path to the SSH public key"
  type        = string
}

variable "authentication_type" {
  description = "Client VPN authentication method. Supported values are certificate and federated."
  type        = string
  default     = "certificate"

  validation {
    condition = contains([
      "certificate",
      "federated",
    ], var.authentication_type)

    error_message = "authentication_type must be either certificate or federated."
  }
}

variable "server_certificate_arn" {
  description = "ACM server certificate ARN."
  type        = string
}

variable "root_certificate_chain_arn" {
  description = "ACM root CA certificate ARN. Required for certificate authentication."
  type        = string
  default     = null
  nullable    = true
}

variable "saml_provider_arn" {
  description = "IAM SAML identity provider ARN. Required for federated Client VPN authentication."
  type        = string
  default     = null
  nullable    = true
}

variable "managed_ad_password" {
  description = "Password for AWS Managed Microsoft AD"
  type        = string
  sensitive   = true
}

variable "ami_id" {
  description = "EC2 AMI ID"
  type        = string
}

#### Tagging Variables #######

variable "org_it_cost_center" {
  description = "Organization-approved IT cost center associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_it_cost_center)) > 0
    error_message = "org_it_cost_center must not be empty."
  }
}

variable "org_department" {
  description = "Organization-approved department associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_department)) > 0
    error_message = "org_department must not be empty."
  }
}

variable "org_cmdb_calculated_app" {
  description = "Organization-approved CMDB calculated application associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_cmdb_calculated_app)) > 0
    error_message = "org_cmdb_calculated_app must not be empty."
  }
}

variable "org_business_criticality" {
  description = "Organization-approved business criticality associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_business_criticality)) > 0
    error_message = "org_business_criticality must not be empty."
  }
}

variable "org_environment" {
  description = "Organization-approved environment classification associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_environment)) > 0
    error_message = "org_environment must not be empty."
  }
}

variable "org_data_classification" {
  description = "Organization-approved data classification associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_data_classification)) > 0
    error_message = "org_data_classification must not be empty."
  }
}

variable "org_project_name" {
  description = "Organization-approved project name associated with the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_project_name)) > 0
    error_message = "org_project_name must not be empty."
  }
}

variable "org_managed_by" {
  description = "Organization-approved identifier for the system or team managing the deployed resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.org_managed_by)) > 0
    error_message = "org_managed_by must not be empty."
  }
}

variable "org_additional_tags" {
  description = "Additional organization-approved tags that do not redefine mandatory organization tags."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition = length(setintersection(
      toset(keys(var.org_additional_tags)),
      toset([
        "org_it_cost_center",
        "org_department",
        "org_cmdb_calculated_app",
        "org_business_criticality",
        "org_environment",
        "org_data_classification",
        "org_project_name",
        "org_managed_by",
      ])
    )) == 0
    error_message = "org_additional_tags must not redefine mandatory organization tag keys."
  }

  validation {
    condition     = alltrue([for key in keys(var.org_additional_tags) : startswith(key, "org_")])
    error_message = "Every org_additional_tags key must start with org_."
  }
}

##################################################################################################
# Portable environment naming
##################################################################################################

variable "naming" {
  description = "Naming components used to derive consistent environment resource names."

  type = object({
    organization             = string
    project                  = string
    project_display_name     = string
    environment              = string
    environment_display_name = string
    region_code              = optional(string)
    suffix                   = optional(string)
  })

  nullable = false

  validation {
    condition = alltrue([
      length(trimspace(var.naming.organization)) > 0,
      length(trimspace(var.naming.project)) > 0,
      length(trimspace(var.naming.project_display_name)) > 0,
      length(trimspace(var.naming.environment)) > 0,
      length(trimspace(var.naming.environment_display_name)) > 0,
      var.naming.region_code == null ? true : length(trimspace(var.naming.region_code)) > 0,
      var.naming.suffix == null ? true : length(trimspace(var.naming.suffix)) > 0,
    ])

    error_message = "Naming components must be non-empty when supplied."
  }
}

variable "resource_name_overrides" {
  description = "Optional exact resource names approved for this environment. Null values use derived names."

  type = object({
    recovery_access_vpc                = optional(string)
    core_recovery_vpc                  = optional(string)
    protected_data_vpc                 = optional(string)
    inspection_vpc                     = optional(string)
    transit_gateway                    = optional(string)
    transit_gateway_recovery_access_rt = optional(string)
    transit_gateway_core_recovery_rt   = optional(string)
    transit_gateway_protected_data_rt  = optional(string)
    transit_gateway_inspection_rt      = optional(string)
    client_vpn                         = optional(string)
    standard_backup_vault              = optional(string)
    air_gapped_backup_vault            = optional(string)
    backup_plan                        = optional(string)
    backup_role                        = optional(string)
    backup_selection                   = optional(string)
    general_kms_alias                  = optional(string)
    network_firewall                   = optional(string)
    network_firewall_policy            = optional(string)
    network_firewall_rule_group        = optional(string)
    network_firewall_logging_kms_alias = optional(string)
    network_firewall_log_group_prefix  = optional(string)
  })

  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for name in values(var.resource_name_overrides) :
      name == null ? true : length(trimspace(name)) > 0
    ])

    error_message = "Resource-name overrides must be null or non-empty strings."
  }
}

##################################################################################################
# Portable environment network allocation
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

variable "security_group_rules" {
  description = <<-EOT
    Security group policy for the Sandbox trust tiers.

    Rules use logical security-group and network-zone names rather than
    hard-coded AWS security group IDs or VPC CIDRs.

    Supported security groups:
      - management
      - core
      - protected

    Supported peer types:
      - security_group
      - vpc
      - cidr

    Supported VPC peers:
      - recovery_access
      - core_recovery
      - protected_data

    For security_group peers, peer must reference one of the supported
    logical security-group names.

    CIDR peers should be used only when a logical VPC or security-group
    reference cannot represent the required access path.
  EOT

  type = list(object({
    name           = string
    direction      = string
    security_group = string

    protocol  = string
    from_port = optional(number)
    to_port   = optional(number)

    peer_type = string
    peer      = string

    description = string
    enabled     = optional(bool, true)
  }))

  validation {
    condition = alltrue([
      for rule in var.security_group_rules :
      contains(
        ["management", "core", "protected"],
        rule.security_group
      )
    ])

    error_message = "security_group must be management, core, or protected."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules :
      contains(["ingress", "egress"], rule.direction)
    ])

    error_message = "direction must be ingress or egress."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules :
      contains(
        ["security_group", "vpc", "cidr"],
        rule.peer_type
      )
    ])

    error_message = "peer_type must be security_group, vpc, or cidr."
  }

  validation {
    condition = (
      length(distinct([
        for rule in var.security_group_rules : rule.name
      ])) == length(var.security_group_rules)
    )

    error_message = "Every security group rule name must be unique."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules :
      rule.peer_type != "security_group" ||
      contains(
        ["management", "core", "protected"],
        rule.peer
      )
    ])

    error_message = "security_group peers must be management, core, or protected."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules :
      rule.peer_type != "vpc" ||
      contains(
        ["recovery_access", "core_recovery", "protected_data"],
        rule.peer
      )
    ])

    error_message = "VPC peers must be recovery_access, core_recovery, or protected_data."
  }
}

################################################################################
# Network Firewall Policy Rules
################################################################################

variable "network_firewall_rules" {
  description = <<-EOT
    Ordered AWS Network Firewall stateful rules.

    Rules are evaluated in the order supplied because the firewall policy
    uses STRICT_ORDER.

    source_zone and destination_zone use logical environment names rather
    than hard-coded CIDRs so the rules remain portable when network_config
    changes.

    Supported zones:
      - recovery_access
      - core_recovery
      - protected_data
      - any

    Supported actions:
      - pass
      - drop

    Supported protocols:
      - ip
      - tcp
      - udp
      - icmp
  EOT

  type = list(object({
    action           = string
    protocol         = string
    source_zone      = string
    source_port      = optional(string, "any")
    destination_zone = string
    destination_port = optional(string, "any")
    description      = string
    sid              = number
    enabled          = optional(bool, true)
  }))


  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      contains(["pass", "drop"], rule.action)
    ])

    error_message = "Each Network Firewall rule action must be either 'pass' or 'drop'."
  }

  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      contains(["ip", "tcp", "udp", "icmp"], rule.protocol)
    ])

    error_message = "Each Network Firewall rule protocol must be ip, tcp, udp, or icmp."
  }

  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      contains(
        ["recovery_access", "core_recovery", "protected_data", "any"],
        rule.source_zone
      ) &&
      contains(
        ["recovery_access", "core_recovery", "protected_data", "any"],
        rule.destination_zone
      )
    ])

    error_message = "Firewall rule zones must be recovery_access, core_recovery, protected_data, or any."
  }

  validation {
    condition = (
      length(distinct([
        for rule in var.network_firewall_rules : rule.sid
      ])) == length(var.network_firewall_rules)
    )

    error_message = "Every Network Firewall rule SID must be unique."
  }

  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      rule.sid > 0 && rule.sid == floor(rule.sid)
    ])

    error_message = "Every Network Firewall rule SID must be a positive whole number."
  }

  validation {
    condition = alltrue(flatten([
      for rule in var.network_firewall_rules : [
        for port in [rule.source_port, rule.destination_port] :
        port == "any" || (
          can(regex("^[0-9]{1,5}(:[0-9]{1,5})?$", port)) &&
          try(
            tonumber(split(":", port)[0]) >= 0 &&
            tonumber(split(":", port)[0]) <= 65535,
            false
          ) &&
          (
            length(split(":", port)) == 1
            ? true
            : try(
              tonumber(split(":", port)[1]) >= 0 &&
              tonumber(split(":", port)[1]) <= 65535 &&
              tonumber(split(":", port)[0]) <= tonumber(split(":", port)[1]),
              false
            )
          )
        )
      ]
    ]))

    error_message = "Firewall ports must be 'any', a port from 0 to 65535, or an ascending range such as '1024:65535'."
  }

  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      contains(["ip", "icmp"], rule.protocol)
      ? rule.source_port == "any" && rule.destination_port == "any"
      : true
    ])

    error_message = "Firewall rules using protocol 'ip' or 'icmp' must use 'any' for source_port and destination_port."
  }

  validation {
    condition = alltrue([
      for rule in var.network_firewall_rules :
      length(trimspace(rule.description)) > 0 &&
      !strcontains(rule.description, "\"") &&
      !strcontains(rule.description, "\\") &&
      !strcontains(rule.description, ";") &&
      !strcontains(rule.description, "\n") &&
      !strcontains(rule.description, "\r")
    ])

    error_message = "Firewall rule descriptions must not be empty or contain double quotes, backslashes, semicolons, or newline characters."
  }
}
