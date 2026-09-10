################################################################################
# Recovery Stack Inputs
#
# This file contains the complete typed input contract for the Recovery root.
#
# Main input sources:
#
#   common-tags.tfvars
#       -> organization tagging inputs
#
#   recovery.tfvars
#       -> workload definitions, naming, access, backup intent, and placement
#
#   AAP Platform dependency contract
#       -> var.platform_contract
#
#   AAP Persistent dependency contract
#       -> var.persistent_resources
#
#   Approved AAP runtime variables
#       -> temporary Recovery lifecycle switches such as demo_ec2_enabled
#
# Terraform does not read Platform or Persistent state directly. AAP reads the
# approved upstream outputs and injects the narrow contracts before planning.
################################################################################

##################################################################################################
# Common Environment Variables
##################################################################################################

variable "aws_region" {
  description = "AWS Region for this environment."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region must not be empty."
  }
}


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


##################################################################################################
# Recovery Workload Lifecycle
##################################################################################################

variable "demo_ec2_enabled" {
  description = "Controls temporary representative EC2 instances used for IRE recovery and traffic-flow validation."
  type        = bool
  default     = false
}


##################################################################################################
# Compute Variables
##################################################################################################

variable "recovery_ssh_key_pairs" {
  description = "Approved SSH key-pair registry. Map keys are the effective AWS EC2 key-pair names."

  type = map(object({
    source          = string
    public_key_path = optional(string)
  }))

  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key_name, config in var.recovery_ssh_key_pairs :
      (
        length(trimspace(key_name)) > 0 &&
        contains(["existing", "managed"], config.source)
      )
    ])

    error_message = "Recovery SSH key-pair names must be non-empty and source must be existing or managed."
  }

  validation {
    condition = alltrue([
      for config in values(var.recovery_ssh_key_pairs) :
      (
        config.source == "managed"
        ? (
          config.public_key_path != null &&
          length(trimspace(config.public_key_path)) > 0
        )
        : config.public_key_path == null
      )
    ])

    error_message = "Managed SSH key pairs require public_key_path; existing key pairs must not set it."
  }
}

#### Tagging Variables #######


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


##################################################################################################
# Persistent Resources Backup Integration
##################################################################################################

variable "backup_integration_enabled" {
  description = "Enable Recovery-stack AWS Backup plan, role, and configuration-driven workload selection using persistent vaults."
  type        = bool
  default     = false

  validation {
    condition = (
      !var.backup_integration_enabled ||
      (
        var.demo_ec2_enabled &&
        anytrue([
          for workload in values(var.recovery_workloads) :
          workload.backup_enabled
        ])
      )
    )

    error_message = "When backup integration is enabled, demo EC2 must be enabled and at least one Recovery workload must have backup_enabled=true."
  }
}

variable "persistent_resources" {
  description = "Persistent resources consumed by Recovery backup integration."

  type = object({
    standard_backup_vault_name  = optional(string)
    air_gapped_backup_vault_arn = optional(string)
  })

  default  = {}
  nullable = false

  validation {
    condition = (
      !var.backup_integration_enabled ||
      (
        try(
          length(
            trimspace(
              var.persistent_resources.standard_backup_vault_name
            )
          ) > 0,
          false
        ) &&
        can(regex(
          "^arn:[^:]+:backup:[^:]+:[0-9]{12}:backup-vault:",
          coalesce(
            var.persistent_resources.air_gapped_backup_vault_arn,
            ""
          )
        ))
      )
    )

    error_message = "When backup integration is enabled, provide the standard Backup vault name and a valid air-gapped Backup vault ARN."
  }
}


##################################################################################################
# Organization Tagging Variables
##################################################################################################

variable "organization_tag_key_prefix" {
  description = "Prefix applied to mandatory organization tag keys. Reusable environments default to org_; private organization configuration may select an approved alternative."
  type        = string
  default     = "org_"
  nullable    = false

  validation {
    condition = (
      trimspace(var.organization_tag_key_prefix) == var.organization_tag_key_prefix &&
      length(var.organization_tag_key_prefix) > 0 &&
      length(var.organization_tag_key_prefix) <= 64 &&
      !startswith(lower(var.organization_tag_key_prefix), "aws:")
    )
    error_message = "organization_tag_key_prefix must be 1-64 characters, contain no surrounding whitespace, and must not use the reserved aws: prefix."
  }
}

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
        "${var.organization_tag_key_prefix}it_cost_center",
        "${var.organization_tag_key_prefix}department",
        "${var.organization_tag_key_prefix}cmdb_calculated_app",
        "${var.organization_tag_key_prefix}business_criticality",
        "${var.organization_tag_key_prefix}environment",
        "${var.organization_tag_key_prefix}data_classification",
        "${var.organization_tag_key_prefix}project_name",
        "${var.organization_tag_key_prefix}managed_by",
      ])
    )) == 0
    error_message = "org_additional_tags must not redefine mandatory organization tag keys."
  }

  validation {
    condition     = alltrue([for key in keys(var.org_additional_tags) : startswith(key, var.organization_tag_key_prefix)])
    error_message = "Every org_additional_tags key must start with organization_tag_key_prefix."
  }
}

##################################################################################################
# Portable environment naming
##################################################################################################
