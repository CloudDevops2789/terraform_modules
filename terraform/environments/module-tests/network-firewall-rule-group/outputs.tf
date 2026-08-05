##################################################################################################
# Validation Outputs
##################################################################################################
output "stateful_rule_groups" {
  description = "Stateful rule groups created by the module test."
  value       = module.network_firewall_rule_groups.stateful_rule_groups
}
output "stateless_rule_groups" {
  description = "Stateless rule groups created by the module test."
  value       = module.network_firewall_rule_groups.stateless_rule_groups
}