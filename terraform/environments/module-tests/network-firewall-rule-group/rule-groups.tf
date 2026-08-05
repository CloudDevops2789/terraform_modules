# No supporting infrastructure is required because rule groups are regional control-plane resources.
module "network_firewall_rule_groups" {
  source                = "../../../modules/network-firewall-rule-group"
  stateful_rule_groups  = local.stateful_rule_groups
  stateless_rule_groups = local.stateless_rule_groups
  tags                  = local.default_tags
}
