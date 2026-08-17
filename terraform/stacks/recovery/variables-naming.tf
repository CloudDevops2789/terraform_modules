##################################################################################################
# Recovery Naming
##################################################################################################

variable "naming" {
  description = "Naming components used to derive consistent Recovery-stack resource names."

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
  description = "Optional exact names for Recovery-stack resources."

  type = object({
    backup_plan      = optional(string)
    backup_role      = optional(string)
    backup_selection = optional(string)
  })

  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for name in values(var.resource_name_overrides) :
      name == null ? true : length(trimspace(name)) > 0
    ])

    error_message = "Recovery resource-name overrides must be null or non-empty strings."
  }
}
