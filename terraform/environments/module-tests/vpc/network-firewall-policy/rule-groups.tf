##################################################################################################
# Supporting Network Firewall Rule Groups
##################################################################################################
module "supporting_rule_groups" {
  source                = "../../../modules/network-firewall-rule-group"
  stateful_rule_groups  = local.supporting_stateful_rule_groups
  stateless_rule_groups = local.supporting_stateless_rule_groups
  tags                  = local.default_tags
}
