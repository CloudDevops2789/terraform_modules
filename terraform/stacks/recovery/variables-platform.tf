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
}

##################################################################################################
# Recovery Workload Placement
##################################################################################################

variable "recovery_workloads" {
  description = "Arbitrary Recovery workloads with configuration-driven Platform placement."

  type = map(object({
    server_name = optional(string)
    vpc_key     = string

    # Workload-specific image and approved administrative access architecture.
    ami_id           = optional(string)
    access_method    = string
    ssh_key_pair_key = optional(string)

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
    condition = (
      !var.demo_ec2_enabled ||
      !anytrue([
        for workload in values(var.recovery_workloads) :
        contains(
          ["ssm", "ssm_with_ssh_fallback"],
          workload.access_method
        )
      ]) ||
      try(
        length(
          trimspace(var.platform_contract.ssm_instance_profile_name)
        ) > 0,
        false
      )
    )

    error_message = "The Platform contract must provide an SSM instance profile when enabled Recovery workloads use SSM."
  }

  validation {
    condition = alltrue([
      for workload in values(var.recovery_workloads) :
      workload.server_name == null ? true : length(trimspace(workload.server_name)) > 0
    ])

    error_message = "Recovery workload server names must be null or non-empty strings."
  }

  validation {
    condition = alltrue([
      for workload in values(var.recovery_workloads) :
      (
        workload.ami_id == null ||
        can(regex("^ami-[0-9a-fA-F]+$", workload.ami_id))
      )
    ])

    error_message = "Recovery workload ami_id values must be null or valid AMI IDs."
  }

  validation {
    condition = alltrue([
      for workload in values(var.recovery_workloads) :
      contains(
        ["none", "ssm", "ssh_key", "ssm_with_ssh_fallback"],
        workload.access_method
      )
    ])

    error_message = "Recovery workload access_method must be none, ssm, ssh_key, or ssm_with_ssh_fallback."
  }

  validation {
    condition = alltrue([
      for workload in values(var.recovery_workloads) :
      (
        contains(
          ["ssh_key", "ssm_with_ssh_fallback"],
          workload.access_method
        )
        ? (
          workload.ssh_key_pair_key != null &&
          contains(
            keys(var.recovery_ssh_key_pairs),
            workload.ssh_key_pair_key
          )
        )
        : workload.ssh_key_pair_key == null
      )
    ])

    error_message = "SSH workloads must reference recovery_ssh_key_pairs; non-SSH workloads must not set ssh_key_pair_key."
  }

  validation {
    condition = (
      !var.demo_ec2_enabled ||
      alltrue([
        for workload in values(var.recovery_workloads) :
        workload.ami_id != null
      ])
    )

    error_message = "Every enabled Recovery workload must define ami_id in recovery_workloads."
  }

  validation {
    condition = length(distinct([
      for workload_key, workload in var.recovery_workloads :
      lower(coalesce(workload.server_name, workload_key))
    ])) == length(var.recovery_workloads)

    error_message = "Effective Recovery workload server names must be unique, ignoring case."
  }

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
