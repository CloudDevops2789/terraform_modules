##################################################################################################
# Naming Variables
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
