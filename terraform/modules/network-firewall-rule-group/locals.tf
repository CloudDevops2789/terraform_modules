locals {
  ##################################################################################################
  # Stateful Rule Group Normalization
  ##################################################################################################
  # The logical map key remains the Terraform identity. Explicit AWS names and merged tags are kept
  # separate so renaming an AWS resource does not silently change unrelated module instances.
  stateful_rule_groups = {
    for key, rule_group in var.stateful_rule_groups : key => merge(rule_group, {
      tags = merge(var.tags, rule_group.tags)
    })
  }
  ##################################################################################################
  # Stateless Rule Group Normalization
  ##################################################################################################
  # Per-resource tags override common module tags while preserving provider-level default_tags.
  stateless_rule_groups = {
    for key, rule_group in var.stateless_rule_groups : key => merge(rule_group, {
      tags = merge(var.tags, rule_group.tags)
    })
  }
}
