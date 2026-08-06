# AWS Network Firewall Rule Group Module
**Status:** Enterprise module
**Terraform:** `>= 1.5.0`
**AWS provider:** `>= 6.0, < 7.0`
## Purpose
This module creates collections of customer-managed AWS Network Firewall stateful, stateful-domain, and stateless rule groups. It is the first layer of the repository's Network Firewall module suite:
```text
network-firewall-rule-group
        ↓
network-firewall-policy
        ↓
network-firewall
```
The module owns only `aws_networkfirewall_rule_group`. Firewall policies, firewalls, VPCs, subnets, routing, logging destinations, and Transit Gateway relationships remain external.
## Enterprise design
- Uses stable logical map keys for Terraform resource addressing.
- Requires explicit AWS resource names so enterprise naming remains caller-controlled.
- Supports multiple rule groups in one module invocation.
- Supports provider-managed and customer-managed KMS encryption.
- Supports raw Suricata rules and structured stateful rules.
- Supports generated domain allowlists and denylists.
- Supports rule variables and resource-group or prefix-list IP set references.
- Supports strongly typed stateless 5-tuple rules and custom CloudWatch metric actions.
- Merges common tags with rule-group-specific tags.
- Exposes rule group ARNs for direct consumption by the firewall-policy module.
## Supported stateful sources
A stateful rule group must define exactly one of:
1. Top-level `rules` containing Suricata flat-format rules.
2. Structured `rule_group.rules_source.rules_string`.
3. Structured `rule_group.rules_source.rules_source_list`.
4. Structured `rule_group.rules_source.stateful_rule`.
The module rejects ambiguous configurations before the AWS API is called.
## Usage
```hcl
module "network_firewall_rule_groups" {
  source = "../../modules/network-firewall-rule-group"
  stateful_rule_groups = {
    domain_denylist = {
      name        = "ire-domain-denylist"
      description = "Blocks known malicious domains."
      capacity    = 100
      rule_group = {
        rules_source = {
          rules_source_list = {
            generated_rules_type = "DENYLIST"
            target_types         = ["HTTP_HOST", "TLS_SNI"]
            targets              = [".malicious.example"]
          }
        }
        stateful_rule_options = {
          rule_order = "DEFAULT_ACTION_ORDER"
        }
      }
    }
    strict_suricata = {
      name        = "ire-strict-suricata"
      description = "Enterprise Suricata controls evaluated in strict order."
      capacity    = 100
      rule_group = {
        rule_variables = {
          ip_sets = {
            HOME_NET = {
              definition = ["10.0.0.0/8"]
            }
          }
        }
        rules_source = {
          rules_string = <<-EOT
            alert tcp $HOME_NET any -> any 443 (msg:"Outbound TLS observed"; flow:to_server; sid:1000001; rev:1;)
          EOT
        }
        stateful_rule_options = {
          rule_order = "STRICT_ORDER"
        }
      }
    }
  }
  stateless_rule_groups = {
    baseline = {
      name        = "ire-stateless-baseline"
      description = "Forwards approved traffic to the stateful engine."
      capacity    = 100
      rule_group = {
        rules_source = {
          stateless_rules_and_custom_actions = {
            custom_action = {
              PublishBaselineMetric = {
                dimensions = ["IREBaseline"]
              }
            }
            stateless_rule = [{
              priority = 100
              rule_definition = {
                actions = ["aws:forward_to_sfe", "PublishBaselineMetric"]
                match_attributes = {
                  source = [{
                    address_definition = "10.0.0.0/8"
                  }]
                  destination = [{
                    address_definition = "10.0.0.0/8"
                  }]
                  protocols = [6]
                }
              }
            }]
          }
        }
      }
    }
  }
  tags = {
    org_project_name = "replace-with-approved-project-name"
    org_managed_by = "Terraform"
  }
}
```
## Inputs
### `stateful_rule_groups`
A map of stateful or stateful-domain rule groups. Each entry requires:
- `name`
- `capacity`
- Exactly one of `rules` or `rule_group`
Optional fields include description, type, encryption configuration, reference sets, rule variables, stateful rule options, and resource-specific tags.
### `stateless_rule_groups`
A map of stateless rule groups. Each entry requires:
- `name`
- `capacity`
- At least one stateless rule
Optional fields include description, encryption configuration, custom metric actions, match attributes, and resource-specific tags.
### `tags`
Common tags merged into every rule group. Resource-specific tags take precedence.
## Outputs
- `stateful_rule_groups`
- `stateful_rule_group_arns`
- `stateless_rule_groups`
- `stateless_rule_group_arns`
## Operational considerations
- Capacity is immutable after creation. Size rule groups for expected lifetime growth.
- Stateful rule order must remain compatible with the consuming firewall policy.
- `STRICT_ORDER` is valid for Suricata strings and standard stateful rules, not generated domain-list rules.
- Customer-managed KMS keys require appropriate key policies for AWS Network Firewall.
- Rule group ARNs are designed to plug directly into `network-firewall-policy`.
## Testing
The companion module test exercises:
- Top-level Suricata rules
- Generated domain-list rules
- Structured stateful 5-tuple rules
- Stateless rules
- Stateless custom metric actions
Run:
```bash
cd terraform/environments/module-tests/network-firewall-rule-group
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

## Repository integration status

The Sandbox uses this module for the reviewed trust chain:

```text
Recovery Access ↔ Core Recovery ↔ Protected Data
```

There is no direct Recovery Access-to-Protected Data pass rule. Environment
CIDRs come from portable input variables; Suricata actions and SIDs remain code.
