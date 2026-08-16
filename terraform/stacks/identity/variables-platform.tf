##################################################################################################
# Platform Contract
##################################################################################################
# Identity consumes only the infrastructure values required from the Platform
# stack. How these values are transported (remote state, AAP orchestration, or
# another approved interface) will be decided separately.

variable "platform_contract" {
  description = "Platform infrastructure values required by the Identity stack."

  type = object({
    core_recovery_vpc_id          = string
    directory_services_subnet_ids = list(string)
  })

  default  = null
  nullable = true

  validation {
    condition = (
      var.platform_contract == null ||
      try(
        length(trimspace(var.platform_contract.core_recovery_vpc_id)) > 0 &&
        length(var.platform_contract.directory_services_subnet_ids) == 2 &&
        alltrue([
          for subnet_id in var.platform_contract.directory_services_subnet_ids :
          length(trimspace(subnet_id)) > 0
        ]),
        false
      )
    )

    error_message = "platform_contract must contain a non-empty Core Recovery VPC ID and exactly two directory-services subnet IDs."
  }
}
