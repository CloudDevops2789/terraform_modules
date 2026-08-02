#variables.tf

/*
1. Common
2. Stateful Rule Variables
3. Stateful Reference Sets
4. Stateful Rules Source
5. Stateful Rule Options
6. Stateless Rules Source
7. Tags */

##################################################################################################
# Stateful Rule Groups
##################################################################################################
# Creates one or more stateful Network Firewall rule groups. The structure
# mirrors the AWS provider schema so enterprise configurations can be migrated
# into this module with minimal translation.
variable "stateful_rule_groups" {
  description = "Stateful Network Firewall rule groups."
  type = map(object({
    description = optional(string)
    capacity    = number
    rule_group = object({
      stateful_rule_options = optional(object({
        rule_order = string
      }))
      rule_variables = optional(any)
      reference_sets = optional(any)
      rules_source   = any
    })
  }))
  default = {}
}

##################################################################################################
# Stateless Rule Groups
##################################################################################################
# Creates one or more stateless Network Firewall rule groups. The structure
# mirrors the AWS provider schema so enterprise configurations can be migrated
# into this module with minimal translation.
variable "stateless_rule_groups" {
  description = "Stateless Network Firewall rule groups."
  type = map(object({
    description = optional(string)
    capacity    = number
    rule_group = object({
      rules_source = any
    })
  }))
  default = {}
}

##################################################################################################
# Tags
##################################################################################################
# Tags applied to every rule group created by this module.
variable "tags" {
  description = "Tags applied to all rule groups."
  type        = map(string)
  default     = {}
}