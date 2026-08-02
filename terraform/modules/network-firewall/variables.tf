##################################################################################################
# Firewall
##################################################################################################

# Friendly name assigned to the Network Firewall and related resources.
variable "name" {
  description = "Name of the AWS Network Firewall."
  type        = string
}

# Optional description visible in the AWS Console.
variable "description" {
  description = "Description of the firewall."
  type        = string
  default     = null
}

# VPC where the firewall will be deployed.
variable "vpc_id" {
  description = "VPC ID where the firewall is deployed."
  type        = string
}

##################################################################################################
# Firewall Subnet Mappings
##################################################################################################
# AWS Network Firewall requires one dedicated subnet mapping per Availability
# Zone. The firewall automatically creates endpoint ENIs inside these subnets.
variable "subnet_mappings" {
  description = "Dedicated firewall subnets keyed by logical Availability Zone."
  type = map(object({
    subnet_id = string
  }))
}

##################################################################################################
# Protection Settings
##################################################################################################
# These settings help protect production firewalls from accidental deletion or
# modification. They are disabled by default for module tests and sandbox
# environments.
variable "delete_protection" {
  description = "Enable delete protection."
  type        = bool
  default     = false
}

variable "subnet_change_protection" {
  description = "Enable subnet change protection."
  type        = bool
  default     = false
}

variable "firewall_policy_change_protection" {
  description = "Enable firewall policy change protection."
  type        = bool
  default     = false
}

##################################################################################################
# Firewall Policy
##################################################################################################
# Default stateless actions applied before traffic reaches the stateful engine.
# Most enterprise deployments simply forward traffic to the Stateful Firewall
# Engine (SFE).
variable "firewall_policy" {
  description = "Firewall policy configuration."
  type = object({
    stateless_default_actions          = list(string)
    stateless_fragment_default_actions = list(string)
  })
  default = {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
  }
}

##################################################################################################
# Stateful Rule Groups
##################################################################################################
# Rule groups created by this module. The caller supplies Suricata rule text.
variable "create_stateful_rule_groups" {
  description = "Create stateful rule groups."
  type        = bool
  default     = true
}

variable "stateful_rule_groups" {
  description = "Stateful rule groups created by this module."
  type = map(object({
    capacity     = number
    description  = optional(string)
    rules_string = string
    priority     = optional(number)
  }))
  default = {}
}

# Existing stateful rule groups managed outside this module.
variable "existing_stateful_rule_groups" {
  description = "Existing stateful rule groups managed outside this module."
  type = map(object({
    arn      = string
    priority = optional(number)
  }))
  default = {}
}

##################################################################################################
# Stateless Rule Groups
##################################################################################################
# Stateless rule groups created by this module. Existing enterprise rule groups
# can also be attached without being managed by Terraform.
variable "create_stateless_rule_groups" {
  description = "Create stateless rule groups."
  type        = bool
  default     = true
}

variable "stateless_rule_groups" {
  description = "Stateless rule groups created by this module."
  type = map(object({
    capacity    = number
    description = optional(string)
    priority    = optional(number)
    rules       = list(any)
  }))
  default = {}
}

variable "existing_stateless_rule_groups" {
  description = "Existing stateless rule groups managed outside this module."
  type = map(object({
    arn      = string
    priority = optional(number)
  }))
  default = {}
}

##################################################################################################
# Logging
##################################################################################################
# Logging destinations are optional. The module supports CloudWatch Logs, S3,
# and Kinesis Data Firehose so the same module can be used across home labs and
# enterprise environments.
variable "logging" {
  description = "Firewall logging configuration."
  type = object({
    cloudwatch = optional(object({
      enabled        = bool
      log_group_name = string
    }))
    s3 = optional(object({
      enabled     = bool
      bucket_name = string
      prefix      = optional(string)
    }))
    firehose = optional(object({
      enabled             = bool
      delivery_stream_arn = string
    }))
  })
  default = {}
}

##################################################################################################
# Tags
##################################################################################################
# Tags applied to every resource created by this module.
variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}