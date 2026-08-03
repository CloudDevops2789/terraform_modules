##################################################################################################
# Stateful Rule Group Outputs
##################################################################################################
# The object map preserves logical keys so downstream firewall-policy modules can attach groups
# without reconstructing names or performing provider lookups.
output "stateful_rule_groups" {
  description = "Stateful rule group attributes keyed by the caller's logical identifiers."
  value = {
    for key, rule_group in aws_networkfirewall_rule_group.stateful : key => {
      arn          = rule_group.arn
      id           = rule_group.id
      name         = rule_group.name
      type         = rule_group.type
      update_token = rule_group.update_token
    }
  }
}
output "stateful_rule_group_arns" {
  description = "Stateful rule group ARNs keyed by logical identifiers."
  value = {
    for key, rule_group in aws_networkfirewall_rule_group.stateful : key => rule_group.arn
  }
}
##################################################################################################
# Stateless Rule Group Outputs
##################################################################################################
output "stateless_rule_groups" {
  description = "Stateless rule group attributes keyed by the caller's logical identifiers."
  value = {
    for key, rule_group in aws_networkfirewall_rule_group.stateless : key => {
      arn          = rule_group.arn
      id           = rule_group.id
      name         = rule_group.name
      type         = rule_group.type
      update_token = rule_group.update_token
    }
  }
}
output "stateless_rule_group_arns" {
  description = "Stateless rule group ARNs keyed by logical identifiers."
  value = {
    for key, rule_group in aws_networkfirewall_rule_group.stateless : key => rule_group.arn
  }
}
