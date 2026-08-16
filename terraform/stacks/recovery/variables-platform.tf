##################################################################################################
# Generic Platform Contract
##################################################################################################

variable "platform_contract" {
  description = "Topology-agnostic Platform values available to Recovery workloads."

  type = object({
    subnet_ids = map(
      map(string)
    )

    subnet_ids_by_group = map(
      map(list(string))
    )

    security_group_ids = map(string)

    ssm_instance_profile_name = optional(string)
  })

  default  = null
  nullable = true

  validation {
    condition = (
      !(var.demo_ec2_enabled && var.demo_ec2_access_method == "ssm") ||
      try(
        length(
          trimspace(var.platform_contract.ssm_instance_profile_name)
        ) > 0,
        false
      )
    )

    error_message = "The Platform contract must provide an SSM instance profile when Recovery workloads use SSM."
  }
}

##################################################################################################
# Recovery Workload Placement
##################################################################################################

variable "recovery_workloads" {
  description = "Arbitrary Recovery workloads with configuration-driven Platform placement."

  type = map(object({
    vpc_key = string

    # Select either one exact subnet or a logical subnet group.
    subnet_key   = optional(string)
    subnet_group = optional(string)
    subnet_index = optional(number, 0)

    security_group_keys = set(string)

    instance_type               = optional(string, "t3.micro")
    associate_public_ip_address = optional(bool, false)

    backup_enabled = optional(bool, false)
  }))

  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for workload in values(var.recovery_workloads) :
      (
        (workload.subnet_key != null ? 1 : 0) +
        (workload.subnet_group != null ? 1 : 0)
      ) == 1
    ])

    error_message = "Every Recovery workload must select exactly one of subnet_key or subnet_group."
  }

  validation {
    condition = alltrue([
      for workload in values(var.recovery_workloads) :
      (
        length(trimspace(workload.vpc_key)) > 0 &&
        length(workload.security_group_keys) > 0 &&
        workload.subnet_index >= 0 &&
        floor(workload.subnet_index) == workload.subnet_index &&
        length(trimspace(workload.instance_type)) > 0
      )
    ])

    error_message = "Every Recovery workload must contain valid placement, security-group, subnet-index, and instance-type configuration."
  }

  validation {
    condition = (
      !var.demo_ec2_enabled ||
      length(var.recovery_workloads) > 0
    )

    error_message = "At least one recovery_workloads entry is required when demo EC2 is enabled."
  }

  validation {
    condition = (
      !var.demo_ec2_enabled ||
      (
        var.platform_contract != null &&
        try(
          alltrue([
            for workload in values(var.recovery_workloads) :
            (
              (
                workload.subnet_key != null
                ? contains(
                  keys(
                    var.platform_contract.subnet_ids[
                      workload.vpc_key
                    ]
                  ),
                  workload.subnet_key
                )
                : (
                  contains(
                    keys(
                      var.platform_contract.subnet_ids_by_group[
                        workload.vpc_key
                      ]
                    ),
                    workload.subnet_group
                  ) &&
                  length(
                    var.platform_contract.subnet_ids_by_group[
                      workload.vpc_key
                      ][
                      workload.subnet_group
                    ]
                  ) > workload.subnet_index
                )
              ) &&
              alltrue([
                for security_group_key in workload.security_group_keys :
                contains(
                  keys(var.platform_contract.security_group_ids),
                  security_group_key
                )
              ])
            )
          ]),
          false
        )
      )
    )

    error_message = "Every enabled Recovery workload must resolve to existing Platform subnet and security-group selectors."
  }
}
