##################################################################################################
# Common Tags
##################################################################################################
variable "tags" {
  description = "Tags applied to every Network Firewall policy created by this module."
  type        = map(string)
  default     = {}
}
##################################################################################################
# Firewall Policies
##################################################################################################
# The map key is a stable Terraform identity. The AWS firewall policy name remains explicit so the
# consuming environment retains full control over enterprise naming standards.
variable "firewall_policies" {
  description = "AWS Network Firewall policies keyed by stable logical identifiers."
  type = map(object({
    name        = string
    description = optional(string)
    encryption_configuration = optional(object({
      type   = string
      key_id = optional(string)
    }))
    firewall_policy = object({
      enable_tls_session_holding = optional(bool)
      policy_variables = optional(object({
        rule_variables = map(object({
          definition = set(string)
        }))
      }))
      stateful_default_actions = optional(set(string))
      stateful_engine_options = optional(object({
        rule_order              = optional(string, "DEFAULT_ACTION_ORDER")
        stream_exception_policy = optional(string, "DROP")
        flow_timeouts = optional(object({
          tcp_idle_timeout_seconds = number
        }))
      }))
      stateful_rule_group_references = optional(map(object({
        resource_arn           = string
        priority               = optional(number)
        deep_threat_inspection = optional(bool)
        override = optional(object({
          action = string
        }))
      })), {})
      stateless_custom_actions = optional(map(object({
        dimensions = set(string)
      })), {})
      stateless_default_actions          = set(string)
      stateless_fragment_default_actions = set(string)
      stateless_rule_group_references = optional(map(object({
        priority     = number
        resource_arn = string
      })), {})
      tls_inspection_configuration_arn = optional(string)
    })
    tags = optional(map(string), {})
  }))
  default = {}
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      length(policy.name) >= 1 &&
      length(policy.name) <= 128 &&
      can(regex("^[A-Za-z0-9-]+$", policy.name))
    ])
    error_message = "Every firewall policy name must contain 1-128 alphanumeric or hyphen characters."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      policy.description == null || length(policy.description) <= 512
    ])
    error_message = "Firewall policy descriptions must contain no more than 512 characters."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      length(setintersection(
        policy.firewall_policy.stateless_default_actions,
        toset(["aws:drop", "aws:pass", "aws:forward_to_sfe"])
      )) == 1
    ])
    error_message = "stateless_default_actions must contain exactly one standard action: aws:drop, aws:pass, or aws:forward_to_sfe."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      length(setintersection(
        policy.firewall_policy.stateless_fragment_default_actions,
        toset(["aws:drop", "aws:pass", "aws:forward_to_sfe"])
      )) == 1
    ])
    error_message = "stateless_fragment_default_actions must contain exactly one standard action: aws:drop, aws:pass, or aws:forward_to_sfe."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      length(setsubtract(
        setsubtract(
          policy.firewall_policy.stateless_default_actions,
          toset(["aws:drop", "aws:pass", "aws:forward_to_sfe"])
        ),
        toset(keys(policy.firewall_policy.stateless_custom_actions))
      )) == 0
    ])
    error_message = "Every nonstandard stateless default action must match a key in stateless_custom_actions."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      length(setsubtract(
        setsubtract(
          policy.firewall_policy.stateless_fragment_default_actions,
          toset(["aws:drop", "aws:pass", "aws:forward_to_sfe"])
        ),
        toset(keys(policy.firewall_policy.stateless_custom_actions))
      )) == 0
    ])
    error_message = "Every nonstandard stateless fragment default action must match a key in stateless_custom_actions."
  }
  validation {
    condition = alltrue(flatten([
      for policy in values(var.firewall_policies) : [
        for action_name, action in policy.firewall_policy.stateless_custom_actions :
        length(action_name) >= 1 &&
        length(action_name) <= 128 &&
        length(action.dimensions) >= 1
      ]
    ]))
    error_message = "Stateless custom action names must contain 1-128 characters and define at least one metric dimension."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      policy.firewall_policy.stateful_engine_options == null ||
      contains(
        ["DEFAULT_ACTION_ORDER", "STRICT_ORDER"],
        policy.firewall_policy.stateful_engine_options.rule_order
      )
    ])
    error_message = "stateful_engine_options.rule_order must be DEFAULT_ACTION_ORDER or STRICT_ORDER."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      policy.firewall_policy.stateful_engine_options == null ||
      contains(
        ["DROP", "CONTINUE", "REJECT"],
        policy.firewall_policy.stateful_engine_options.stream_exception_policy
      )
    ])
    error_message = "stateful_engine_options.stream_exception_policy must be DROP, CONTINUE, or REJECT."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      policy.firewall_policy.stateful_engine_options == null ||
      policy.firewall_policy.stateful_engine_options.flow_timeouts == null ||
      (
        policy.firewall_policy.stateful_engine_options.flow_timeouts.tcp_idle_timeout_seconds >= 60 &&
        policy.firewall_policy.stateful_engine_options.flow_timeouts.tcp_idle_timeout_seconds <= 6000
      )
    ])
    error_message = "TCP idle timeout must be between 60 and 6000 seconds."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      policy.firewall_policy.stateful_default_actions == null ||
      (
        policy.firewall_policy.stateful_engine_options != null &&
        policy.firewall_policy.stateful_engine_options.rule_order == "STRICT_ORDER"
      )
    ])
    error_message = "stateful_default_actions can be configured only when stateful rule order is STRICT_ORDER."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      policy.firewall_policy.stateful_default_actions == null ||
      length(setsubtract(
        policy.firewall_policy.stateful_default_actions,
        toset([
          "aws:drop_strict",
          "aws:drop_established",
          "aws:alert_strict",
          "aws:alert_established",
          "aws:drop_established_app_layer",
          "aws:alert_established_app_layer",
          "aws:drop_established_app_layer_to_server",
          "aws:alert_established_app_layer_to_server"
        ])
      )) == 0
    ])
    error_message = "stateful_default_actions contains an unsupported AWS Network Firewall action."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      (
        policy.firewall_policy.stateful_engine_options != null &&
        policy.firewall_policy.stateful_engine_options.rule_order == "STRICT_ORDER"
      ) ?
      alltrue([
        for reference in values(policy.firewall_policy.stateful_rule_group_references) :
        reference.priority != null
      ]) :
      alltrue([
        for reference in values(policy.firewall_policy.stateful_rule_group_references) :
        reference.priority == null
      ])
    ])
    error_message = "Stateful rule group priorities are required for STRICT_ORDER and must be omitted for DEFAULT_ACTION_ORDER."
  }
  validation {
    condition = alltrue(flatten([
      for policy in values(var.firewall_policies) : [
        for reference in values(policy.firewall_policy.stateful_rule_group_references) :
        reference.priority == null || (reference.priority >= 1 && reference.priority <= 65535)
      ]
    ]))
    error_message = "Stateful rule group reference priorities must be between 1 and 65535."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      length([
        for reference in values(policy.firewall_policy.stateful_rule_group_references) :
        reference.priority if reference.priority != null
        ]) == length(distinct([
          for reference in values(policy.firewall_policy.stateful_rule_group_references) :
          reference.priority if reference.priority != null
      ]))
    ])
    error_message = "Stateful rule group reference priorities must be unique within each firewall policy."
  }
  validation {
    condition = alltrue(flatten([
      for policy in values(var.firewall_policies) : [
        for reference in values(policy.firewall_policy.stateful_rule_group_references) :
        reference.override == null || reference.override.action == "DROP_TO_ALERT"
      ]
    ]))
    error_message = "Stateful rule group override action must be DROP_TO_ALERT."
  }
  validation {
    condition = alltrue(flatten([
      for policy in values(var.firewall_policies) : [
        for reference in values(policy.firewall_policy.stateless_rule_group_references) :
        reference.priority >= 1 && reference.priority <= 65535
      ]
    ]))
    error_message = "Stateless rule group reference priorities must be between 1 and 65535."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      length([
        for reference in values(policy.firewall_policy.stateless_rule_group_references) :
        reference.priority
        ]) == length(distinct([
          for reference in values(policy.firewall_policy.stateless_rule_group_references) :
          reference.priority
      ]))
    ])
    error_message = "Stateless rule group reference priorities must be unique within each firewall policy."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      policy.firewall_policy.policy_variables == null ? true : (
        toset(keys(policy.firewall_policy.policy_variables.rule_variables)) == toset(["HOME_NET"])
      )
    ])
    error_message = "Firewall policy rule variables must define exactly one key named HOME_NET."
  }
  validation {
    condition = alltrue(flatten([
      for policy in values(var.firewall_policies) : [
        for variable in policy.firewall_policy.policy_variables == null ? {} : policy.firewall_policy.policy_variables.rule_variables :
        length(variable.definition) > 0
      ]
    ]))
    error_message = "Every firewall policy rule variable must contain at least one CIDR definition."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      policy.firewall_policy.enable_tls_session_holding != true ||
      policy.firewall_policy.tls_inspection_configuration_arn != null
    ])
    error_message = "TLS session holding requires tls_inspection_configuration_arn."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      policy.firewall_policy.tls_inspection_configuration_arn == null ||
      can(regex("^arn:", policy.firewall_policy.tls_inspection_configuration_arn))
    ])
    error_message = "tls_inspection_configuration_arn must be an ARN."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      policy.encryption_configuration == null ||
      contains(["AWS_OWNED_KMS_KEY", "CUSTOMER_KMS"], policy.encryption_configuration.type)
    ])
    error_message = "Encryption type must be AWS_OWNED_KMS_KEY or CUSTOMER_KMS."
  }
  validation {
    condition = alltrue([
      for policy in values(var.firewall_policies) :
      policy.encryption_configuration == null ||
      policy.encryption_configuration.type != "CUSTOMER_KMS" ||
      try(policy.encryption_configuration.key_id, null) != null
    ])
    error_message = "CUSTOMER_KMS encryption requires key_id."
  }
}
