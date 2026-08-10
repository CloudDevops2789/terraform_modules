# Security Group Rule Module

Creates standalone security group ingress and egress rules from a single flat map, splitting them by direction internally.

Designed to be used with the [`security-group`](../security-group) module, which creates the groups these rules attach to. See that module's README for why rules are managed separately.

---

## Usage

```hcl
module "security_group_rule" {
  source = "../../modules/security-group-rule"

  rules = {

    # Allow SSH from a whole VPC tier, referenced by CIDR.
    core-ssh = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["core"]
      description       = "Allow SSH from the recovery access tier"
      ip_protocol       = "tcp"
      from_port         = 22
      to_port           = 22

      cidr_ipv4         = module.recovery_access.vpc_cidr
    }

    # Allow HTTPS from another security group. Preferred over a CIDR
    # when both ends are inside AWS, since it survives IP changes.
    core-https-from-management = {
      type              = "ingress"
      security_group_id = module.security_group.security_group_ids["core"]
      description       = "Allow HTTPS from the management security group"
      ip_protocol = "tcp"
      from_port   = 443
      to_port     = 443

      referenced_security_group_id = module.security_group.security_group_ids["management"]
    }

    # Unrestricted egress. ip_protocol "-1" means all protocols,
    # so no port range is given.
    core-egress = {
      type              = "egress"
      security_group_id = module.security_group.security_group_ids["core"]
      description       = "Allow outbound traffic from the core tier"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}
```

---

## Inputs

| Name | Type | Default | Required | Description |
|---|---|---|:---:|---|
| `rules` | `map(object)` | `{}` | no | Rules to create, keyed by a name of your choosing. |

### `rules` object

| Attribute | Type | Default | Description |
|---|---|---|---|
| `type` | `string` | required | `"ingress"` or `"egress"`. Determines which resource type is created. |
| `security_group_id` | `string` | required | Group this rule attaches to. |
| `description` | `string` | `null` | Optional description applied to the AWS security group rule. |
| `ip_protocol` | `string` | required | Protocol name or number, for example `"tcp"`, `"udp"`, `"icmp"`, `"icmpv6"`, `"6"`, `"17"`, `"1"`, `"58"`, or `"-1"` for all protocols. |
| `from_port` | `number` | `null` | Start of the port range. Omit when `ip_protocol` is `"-1"`. |
| `to_port` | `number` | `null` | End of the port range. Omit when `ip_protocol` is `"-1"`. |
| `cidr_ipv4` | `string` | `null` | IPv4 CIDR source or destination. |
| `cidr_ipv6` | `string` | `null` | IPv6 CIDR source or destination. |
| `prefix_list_id` | `string` | `null` | Managed prefix list source or destination. |
| `referenced_security_group_id` | `string` | `null` | Another security group as source or destination. |

**Set exactly one source.** Each rule must configure exactly one of `cidr_ipv4`, `cidr_ipv6`, `prefix_list_id`, or `referenced_security_group_id`. The module validates this contract before resource creation.

IPv4 and IPv6 CIDR attributes are also validated for correct CIDR syntax and address family.

---

### Rule validation

The module validates rule inputs before passing them to the AWS provider.

The following conditions are enforced:

- `type` must be `ingress` or `egress`.
- `security_group_id` and `ip_protocol` must not be empty.
- Exactly one rule source or destination must be configured.
- Configured source values must not be empty strings.
- `cidr_ipv4` must contain a valid IPv4 CIDR.
- `cidr_ipv6` must contain a valid IPv6 CIDR.
- `from_port` and `to_port` must either both be supplied or both be omitted.
- `ip_protocol = "-1"` must not specify ports.
- TCP and UDP rules require whole-number ports from `0` to `65535`, with `from_port <= to_port`.
- ICMP rules use `from_port` as the ICMP type and `to_port` as the ICMP code. Values must be whole numbers from `-1` to `255`. When type is `-1`, code must also be `-1`.
- ICMPv6 rules may omit type and code, or use whole-number values from `-1` to `255`. When type is `-1`, code must also be `-1`.
- Optional descriptions must be non-empty when supplied and cannot exceed 255 characters.

Protocol-specific validation recognizes both names and standard protocol numbers:

| Protocol | Name | Number |
|---|---|---:|
| TCP | `tcp` | `6` |
| UDP | `udp` | `17` |
| ICMP | `icmp` | `1` |
| ICMPv6 | `icmpv6` | `58` |

Other valid AWS protocol names or numbers remain supported by the reusable module, but protocol-specific port semantics for those protocols are delegated to the AWS provider.

---

## Outputs

This module currently exposes no outputs. Rule IDs are not returned, so a rule cannot be referenced from elsewhere in a configuration. If you need that — for example to build a dependency on a specific rule — it would need to be added.

---

## Design notes

**One flat map, split internally.** AWS models ingress and egress as two distinct resource types, but forcing callers to maintain two separate maps is awkward. This module accepts one map and filters it into two using comprehensions with an `if` clause, so a rule's direction is just another attribute.

**Standalone rules, not inline blocks.** `aws_vpc_security_group_ingress_rule` and `aws_vpc_security_group_egress_rule` are the modern replacements for the deprecated `aws_security_group_rule`. Each resource manages exactly one rule, so Terraform can add or remove individual rules without rewriting the group.

**Prefer group references over CIDRs.** When both ends of a rule are inside AWS, `referenced_security_group_id` is more robust than a CIDR: it keeps working when addressing changes, and it expresses intent ("the app tier") rather than an implementation detail ("this address range").

**Every rule is a deliberate grant.** There are no implicit rules. A group with no rules from this module permits nothing in either direction.

**Fail early on invalid rule contracts.** The module validates structural rule requirements, mutually exclusive source attributes, CIDR address families, protocol-specific port semantics, and description constraints before AWS API calls. This provides faster and clearer feedback to callers while keeping the module independent of environment-specific network policy.
---

## Terraform concepts used

| Concept | Where | Why it is used |
|---|---|---|
| Filtered comprehension | `security-group-rule.tf` | `for k, v in map : k => v if condition` splits one map by direction |
| `for_each` over a map | `security-group-rule.tf` | One resource per rule, addressed by the caller's key |
| `try()` | `security-group-rule.tf` | Resolve optional attributes to `null` so the provider omits them |
| `optional()` in object types | `variables.tf` | Mutually exclusive attributes, all optional |
| `locals` inside a resource file | `security-group-rule.tf` | Locals may be declared in any `.tf` file, not only `locals.tf` |

---

## Requirements

Inherited from the calling configuration. This module has no populated `versions.tf`; see the repository README's known limitations.

| Requirement | Version |
|---|---|
| Terraform | `>= 1.10.0` (as used by the sandbox environment) |
| AWS provider | `~> 6.0` |
