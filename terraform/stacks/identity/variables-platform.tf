##################################################################################################
# Generic Platform Contract
##################################################################################################

variable "platform_contract" {
  description = "Topology-agnostic Platform values available to the Identity stack."

  type = object({
    vpc_ids   = map(string)
    vpc_cidrs = map(string)

    subnet_ids_by_group = map(
      map(list(string))
    )
  })

  default  = null
  nullable = true
}

variable "identity_placement" {
  description = "Configuration-driven placement of Identity services within the Platform topology."

  type = object({
    vpc_key               = string
    subnet_group          = string
    required_subnet_count = optional(number, 2)
  })

  default  = null
  nullable = true

  validation {
    condition = (
      var.identity_placement == null ||
      (
        length(trimspace(var.identity_placement.vpc_key)) > 0 &&
        length(trimspace(var.identity_placement.subnet_group)) > 0 &&
        var.identity_placement.required_subnet_count > 0 &&
        floor(var.identity_placement.required_subnet_count) ==
        var.identity_placement.required_subnet_count
      )
    )

    error_message = "identity_placement must contain valid logical Platform selectors."
  }

  validation {
    condition = (
      var.platform_contract == null ||
      var.identity_placement == null ||
      try(
        contains(
          keys(var.platform_contract.vpc_ids),
          var.identity_placement.vpc_key
        ) &&
        contains(
          keys(
            var.platform_contract.subnet_ids_by_group[
              var.identity_placement.vpc_key
            ]
          ),
          var.identity_placement.subnet_group
        ) &&
        length(
          var.platform_contract.subnet_ids_by_group[
            var.identity_placement.vpc_key
            ][
            var.identity_placement.subnet_group
          ]
        ) >= var.identity_placement.required_subnet_count,
        false
      )
    )

    error_message = "identity_placement must resolve to an existing Platform VPC and enough subnets in the selected subnet group."
  }
}
