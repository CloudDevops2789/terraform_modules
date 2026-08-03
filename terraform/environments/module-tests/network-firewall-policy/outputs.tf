##################################################################################################
# Validation Outputs
##################################################################################################
output "firewall_policies" {
  description = "Firewall policies created by the module test."
  value       = module.network_firewall_policy.firewall_policies
}
output "supporting_rule_group_arns" {
  description = "Supporting rule group ARNs used by the strict-order policy."
  value = {
    stateful  = module.supporting_rule_groups.stateful_rule_group_arns
    stateless = module.supporting_rule_groups.stateless_rule_group_arns
  }
}
