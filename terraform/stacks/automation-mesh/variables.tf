variable "aws_region" {
  description = "AWS Region selected by the deployment runtime."
  type        = string
}

variable "automation_mesh_enabled" {
  description = "Whether to create the Automation Mesh execution node and its security group."
  type        = bool
  default     = false
  nullable    = false
}

variable "instance_name" {
  description = "EC2 Name tag and hostname-aligned identifier. Limited to 15 characters for enterprise naming compatibility."
  type        = string
  default     = "aap-exec-01"
  nullable    = false

  validation {
    condition = (
      length(trimspace(var.instance_name)) > 0 &&
      length(var.instance_name) <= 15
    )
    error_message = "instance_name must contain 1 to 15 characters."
  }
}

variable "vpc_id" {
  description = "Existing VPC that owns the selected subnet."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = !var.automation_mesh_enabled || try(
      can(regex("^vpc-[0-9a-f]+$", var.vpc_id)),
      false
    )
    error_message = "Enabled Automation Mesh requires a valid existing VPC ID."
  }
}

variable "subnet_id" {
  description = "Existing private subnet for the execution node."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = !var.automation_mesh_enabled || try(
      can(regex("^subnet-[0-9a-f]+$", var.subnet_id)),
      false
    )
    error_message = "Enabled Automation Mesh requires a valid existing subnet ID."
  }
}

variable "ami_id" {
  description = "Existing x86_64 Linux AMI ID."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = !var.automation_mesh_enabled || try(
      can(regex("^ami-[0-9a-f]+$", var.ami_id)),
      false
    )
    error_message = "Enabled Automation Mesh requires a valid AMI ID."
  }
}

variable "instance_type" {
  description = "EC2 instance type selected by the target environment."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.instance_type)) > 0
    error_message = "instance_type must not be empty."
  }
}

variable "instance_profile_name" {
  description = "Existing EC2 instance profile with the approved runtime permissions."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = !var.automation_mesh_enabled || try(
      length(trimspace(var.instance_profile_name)) > 0,
      false
    )
    error_message = "Enabled Automation Mesh requires an existing instance profile name."
  }
}

variable "ssh_key_name" {
  description = "Existing EC2 key-pair name. Omit when SSH ingress is disabled."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      var.ssh_key_name == null
      ? true
      : length(trimspace(var.ssh_key_name)) > 0
    )
    error_message = "ssh_key_name must be null or a non-empty string."
  }
}

variable "ssh_ingress_cidrs" {
  description = "Approved IPv4 CIDRs allowed to reach TCP 22. Leave empty for SSM-only access."
  type        = set(string)
  default     = []
  nullable    = false

  validation {
    condition = alltrue([
      for cidr in var.ssh_ingress_cidrs :
      can(cidrhost(cidr, 0)) && !strcontains(cidr, ":") && cidr != "0.0.0.0/0"
    ])
    error_message = "ssh_ingress_cidrs must contain restricted IPv4 CIDRs and cannot include 0.0.0.0/0."
  }

  validation {
    condition = (
      length(var.ssh_ingress_cidrs) == 0 ||
      try(length(trimspace(var.ssh_key_name)) > 0, false)
    )
    error_message = "SSH ingress requires an existing ssh_key_name."
  }
}

variable "mesh_ingress_cidrs" {
  description = "Approved Automation Mesh peer IPv4 CIDRs allowed to reach TCP 27199."
  type        = set(string)
  default     = []
  nullable    = false

  validation {
    condition = alltrue([
      for cidr in var.mesh_ingress_cidrs :
      can(cidrhost(cidr, 0)) && !strcontains(cidr, ":") && cidr != "0.0.0.0/0"
    ])
    error_message = "mesh_ingress_cidrs must contain restricted IPv4 CIDRs and cannot include 0.0.0.0/0."
  }
}

variable "egress_ipv4_cidrs" {
  description = "IPv4 destinations allowed for outbound traffic. Reachability remains controlled by existing routes and firewalls."
  type        = set(string)
  default     = ["0.0.0.0/0"]
  nullable    = false

  validation {
    condition = (
      length(var.egress_ipv4_cidrs) > 0 &&
      alltrue([
        for cidr in var.egress_ipv4_cidrs :
        can(cidrhost(cidr, 0)) && !strcontains(cidr, ":")
      ])
    )
    error_message = "egress_ipv4_cidrs must contain at least one valid IPv4 CIDR."
  }
}

variable "root_volume" {
  description = "Encrypted gp3 root-volume configuration."
  type = object({
    volume_size = number
    iops        = optional(number, 3000)
    throughput  = optional(number, 125)
    kms_key_id  = optional(string)
  })
  nullable = false

  validation {
    condition = (
      var.root_volume.volume_size > 0 &&
      var.root_volume.iops > 0 &&
      var.root_volume.throughput > 0
    )
    error_message = "root_volume size, IOPS, and throughput must be greater than zero."
  }
}

variable "customer_managed_kms_required" {
  description = "Require root_volume.kms_key_id. Enable this for environments that mandate a customer-managed key."
  type        = bool
  default     = false
  nullable    = false

  validation {
    condition = (
      !var.automation_mesh_enabled ||
      !var.customer_managed_kms_required ||
      try(length(trimspace(var.root_volume.kms_key_id)) > 0, false)
    )
    error_message = "Enabled Automation Mesh requires root_volume.kms_key_id when customer_managed_kms_required is true."
  }
}

variable "enable_detailed_monitoring" {
  description = "Enable EC2 detailed monitoring."
  type        = bool
  default     = false
  nullable    = false
}

variable "enable_termination_protection" {
  description = "Enable EC2 API termination protection. Disable deliberately before an approved destroy."
  type        = bool
  default     = false
  nullable    = false
}

variable "enable_ebs_optimization" {
  description = "Enable EBS optimization for the execution node."
  type        = bool
  default     = true
  nullable    = false
}

variable "instance_metadata_tags" {
  description = "Whether instance tags are available through IMDS."
  type        = string
  default     = "disabled"
  nullable    = false

  validation {
    condition     = contains(["enabled", "disabled"], var.instance_metadata_tags)
    error_message = "instance_metadata_tags must be enabled or disabled."
  }
}

variable "common_tags" {
  description = "Environment-approved tags applied to the security group and EC2 instance."
  type        = map(string)
  default     = {}
  nullable    = false
}
