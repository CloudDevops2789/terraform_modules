##################################################################################################
# Firewall Policy Outputs
##################################################################################################
output "firewall_policies" {
  description = "Firewall policy attributes keyed by the caller's logical identifiers."
  value = {
    for key, policy in aws_networkfirewall_firewall_policy.this : key => {
      arn          = policy.arn
      id           = policy.id
      name         = policy.name
      update_token = policy.update_token
    }
  }
}
output "firewall_policy_arns" {
  description = "Firewall policy ARNs keyed by logical identifiers."
  value = {
    for key, policy in aws_networkfirewall_firewall_policy.this : key => policy.arn
  }
}
