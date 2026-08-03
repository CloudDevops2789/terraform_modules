locals {
  ##################################################################################################
  # Firewall Policy Normalization
  ##################################################################################################
  # Per-policy tags override common module tags while provider-level default_tags remain external.
  firewall_policies = {
    for key, policy in var.firewall_policies : key => merge(policy, {
      tags = merge(var.tags, policy.tags)
    })
  }
}
