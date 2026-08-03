##################################################################################################
# Stateful Rule Groups
##################################################################################################
# Normalizes stateful rule groups into the structure consumed by the AWS
# Network Firewall resources.
locals {
  normalized_stateful_rule_groups = {
    for name, rule_group in var.stateful_rule_groups : name => merge(
      rule_group,
      {
        name = name
      }
    )
  }

##################################################################################################
# Stateless Rule Groups
##################################################################################################
# Normalizes stateless rule groups into the structure consumed by the AWS
# Network Firewall resources.
  normalized_stateless_rule_groups = {
    for name, rule_group in var.stateless_rule_groups : name => merge(
      rule_group,
      {
        name = name
      }
    )
  }
}