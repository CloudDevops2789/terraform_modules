# AWS Network Firewall Policy Module
**Status:** Enterprise module
**Terraform:** `>= 1.5.0`
**AWS provider:** `>= 6.38, < 7.0`
## Purpose
This module creates collections of AWS Network Firewall firewall policies. It is the second layer of the repository's Network Firewall module suite:
```text
network-firewall-rule-group
        ↓
network-firewall-policy
        ↓
network-firewall
```
The module owns only `aws_networkfirewall_firewall_policy`. Rule groups, TLS inspection configurations, KMS keys, resource sharing, firewalls, logging, VPCs, subnets, and routing remain separate concerns.
## Enterprise design
- Uses stable logical map keys for Terraform resource addressing.
- Requires explicit AWS policy names.
- Creates multiple policies in one module invocation.
- Accepts rule group ARNs from created, AWS-managed, shared, or externally managed rule groups.
- Supports default and strict stateful rule ordering.
- Supports stateful and stateless rule group priorities.
- Supports stateless custom CloudWatch metric actions.
- Supports policy-level `HOME_NET` overrides.
- Supports configurable TCP idle timeout and stream exception handling.
- Supports TLS inspection configuration association and TLS session holding.
- Supports stateful managed-rule overrides and deep threat inspection.
- Supports provider-managed and customer-managed KMS encryption.
- Merges common and policy-specific tags.
## Usage
```hcl
module "network_firewall_policy" {
  source = "../../modules/network-firewall-policy"
  firewall_policies = {
    strict_egress = {
      name        = "ire-strict-egress"
      description = "Strict-order egress inspection policy."
      firewall_policy = {
        policy_variables = {
          rule_variables = {
            HOME_NET = {
              definition = ["10.0.0.0/8"]
            }
          }
        }
        stateful_engine_options = {
          rule_order              = "STRICT_ORDER"
          stream_exception_policy = "DROP"
          flow_timeouts = {
            tcp_idle_timeout_seconds = 350
          }
        }
        stateful_default_actions = [
          "aws:drop_strict",
          "aws:alert_strict"
        ]
        stateful_rule_group_references = {
          enterprise_suricata = {
            priority     = 100
            resource_arn = module.network_firewall_rule_groups.stateful_rule_group_arns["enterprise_suricata"]
          }
        }
        stateless_custom_actions = {
          PublishDefaultTraffic = {
            dimensions = ["DefaultTraffic"]
          }
        }
        stateless_default_actions = [
          "aws:forward_to_sfe",
          "PublishDefaultTraffic"
        ]
        stateless_fragment_default_actions = [
          "aws:forward_to_sfe"
        ]
        stateless_rule_group_references = {
          baseline = {
            priority     = 100
            resource_arn = module.network_firewall_rule_groups.stateless_rule_group_arns["baseline"]
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
## Rule-order compatibility
When `STRICT_ORDER` is selected:
- Every stateful rule group reference requires a unique priority.
- Referenced stateful rule groups must also use strict ordering.
- Stateful default actions may be configured.
When `DEFAULT_ACTION_ORDER` is selected:
- Stateful reference priorities must be omitted.
- Stateful default actions must be omitted.
## Existing and managed rule groups
The module accepts ARNs directly. This allows policies to reference:
- Rule groups produced by `network-firewall-rule-group`
- AWS-managed rule groups
- Rule groups shared with AWS RAM
- Rule groups managed by another Terraform state
No data-source lookup or ownership transfer is performed.
## TLS inspection
Set `tls_inspection_configuration_arn` to attach an existing TLS inspection configuration. Set `enable_tls_session_holding = true` only when that ARN is present.
## Outputs
- `firewall_policies`
- `firewall_policy_arns`
## Testing
The companion module test creates supporting strict-order stateful and stateless rule groups, then creates:
- One strict-order policy with rule references, policy variables, flow timeout, and a custom metric action
- One default-action-order policy with no rule group dependencies
Run:
```bash
cd terraform/environments/module-tests/network-firewall-policy
terraform init
terraform validate
terraform plan
terraform apply
terraform plan
terraform destroy
```

## Repository integration status

The Sandbox uses this module for one strict-order centralized inspection policy.
Stateless traffic is forwarded to the stateful engine, unmatched stateful
traffic is dropped and alerted, and the policy references the Sandbox
segmentation rule group.
