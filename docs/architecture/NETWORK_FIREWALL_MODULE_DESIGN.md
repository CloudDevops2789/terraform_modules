# AWS Network Firewall Module Suite Design
**Version:** 1.0
**Status:** Design Specification (Normative)
**Applies To:**
- terraform/modules/network-firewall-rule-group
- terraform/modules/network-firewall-policy
- terraform/modules/network-firewall
**Owner:** Cyber Security Resilience and Recovery Team

---

# 1. Purpose

This document defines the architecture, design principles, module boundaries, public interfaces, implementation strategy, and enterprise design decisions governing the AWS Network Firewall module suite.

This document serves as the authoritative design specification for all Network Firewall modules contained within this repository.

Terraform implementation shall conform to this specification.

---

# 2. Scope

The module suite provides reusable Infrastructure-as-Code for AWS Network Firewall.

The objective is to expose the complete AWS Network Firewall capability while maintaining:

- Enterprise compatibility
- Stable public interfaces
- Strong typing
- Reusable components
- Independent module lifecycle
- AWS Well-Architected alignment

---

# 3. Design Goals

The module suite shall:

- Mirror AWS service boundaries.
- Avoid unnecessary abstraction.
- Support enterprise deployment patterns.
- Support home lab validation.
- Remain composable.
- Support independently managed enterprise resources.
- Minimize translation between Terraform inputs and AWS concepts.

---

# 4. Architectural Philosophy

AWS Network Firewall consists of three independent AWS resources:

- Rule Groups
- Firewall Policies
- Firewalls

The Terraform module suite shall mirror this architecture.

Each module owns exactly one AWS capability.

No module owns resources outside its defined responsibility.

---

# 5. Module Architecture

The module suite consists of three independent modules.

```
network-firewall-rule-group
                │
                ▼
network-firewall-policy
                │
                ▼
network-firewall
```

Each module communicates exclusively through Terraform outputs.

Modules shall never invoke other modules internally.

Composition occurs only within Terraform environments.

---

# 6. Module Responsibilities

## network-firewall-rule-group

Responsible for:

- Stateful Rule Groups
- Stateless Rule Groups

Creates:

- aws_networkfirewall_rule_group

Supports:

- Multiple rule groups
- Stateful rule groups
- Stateless rule groups
- Rule Variables
- Reference Sets
- Suricata Rules
- Domain Lists
- Generated Rules
- Custom Actions
- Rule priorities
- Tags

Does not create:

- Firewall Policies
- Firewalls
- Logging
- VPCs
- Route Tables
- Subnets

---

## network-firewall-policy

Responsible for:

- Firewall Policy

Creates:

- aws_networkfirewall_firewall_policy

Consumes:

- Rule Group ARNs

Supports:

- Existing Rule Groups
- Module-created Rule Groups
- Stateful references
- Stateless references
- Default actions
- Fragment actions
- Policy priorities

Does not create:

- Rule Groups
- Firewalls
- VPCs

---

## network-firewall

Responsible for:

- AWS Network Firewall
- Firewall Logging Configuration

Creates:

- aws_networkfirewall_firewall
- aws_networkfirewall_logging_configuration

Consumes:

- Firewall Policy ARN
- VPC
- Firewall Subnets

Supports:

- Existing Firewall Policy
- Logging
- Delete Protection
- Firewall Policy Protection
- Subnet Change Protection

Does not create:

- Rule Groups
- Firewall Policies
- VPC
- Route Tables
- Transit Gateway
- CloudWatch Log Groups

---

# 7. AWS Feature Support

The module suite shall support every feature exposed by the AWS Terraform Provider that is applicable to AWS Network Firewall.

Stateful Rule Groups

Supported:

- Suricata Rules String
- Stateful Rules
- Rule Variables
- IP Sets
- Port Sets
- Reference Sets
- Rule Order

Stateless Rule Groups

Supported:

- Stateless Rules
- Match Attributes
- Custom Actions
- Publish Metrics

Firewall Policies

Supported:

- Stateful Rule Group References
- Stateless Rule Group References
- Default Stateless Actions
- Fragment Default Actions
- Stateful Engine Options

Firewalls

Supported:

- Multi-AZ Deployment
- Firewall Endpoints
- Protection Flags
- Logging
- Endpoint Status

---

# 8. Enterprise Compatibility

Modules shall support both:

Resource Creation

and

Existing Enterprise Resources

Examples include:

- Existing Rule Groups
- Existing Firewall Policies
- Existing CloudWatch Log Groups

Enterprise environments shall not be required to recreate existing infrastructure.

---

# 9. Public API Philosophy

Public interfaces shall closely mirror AWS.

Terraform variables should retain AWS terminology whenever practical.

Examples:

- rule_variables
- reference_sets
- rules_source
- stateful_rule_options
- subnet_mapping

Avoid introducing custom terminology.

---

# 10. Strong Typing

All public variables shall use explicit Terraform types.

Permitted:

- object(...)
- map(...)
- list(...)
- optional(...)

The use of `any` is prohibited unless Terraform cannot accurately represent the AWS schema.

---

# 11. Rule Group Strategy

The Rule Group module manages collections of rule groups.

Example:

```
stateful_rule_groups

├── malware

├── exploit

└── dns

stateless_rule_groups

├── allow-http

├── drop-invalid

└── vpn
```

The module shall support creating multiple rule groups within a single deployment.

---

# 12. Firewall Policy Strategy

Firewall Policies shall consume Rule Group outputs.

Rule Group creation remains independent.

Policies shall support:

- Module-created Rule Groups
- Existing Rule Groups

The module shall automatically normalize policy references.

---

# 13. Firewall Strategy

The Firewall module shall consume an existing Firewall Policy ARN.

The module shall not manage Rule Groups.

Firewall deployment concerns include:

- Endpoint creation
- Logging configuration
- Protection flags
- Status outputs

Infrastructure relationships remain external.

---

# 14. Logging Strategy

Logging configuration belongs exclusively to the Firewall module.

Supported destinations:

- CloudWatch Logs
- Amazon S3
- Amazon Kinesis Data Firehose

The module shall configure logging.

The module shall not create logging infrastructure.

---

# 15. Resource Ownership

Ownership boundaries shall remain strict.

Rule Group Module

Owns:

- Rule Groups

Firewall Policy Module

Owns:

- Firewall Policy

Firewall Module

Owns:

- Firewall
- Logging Configuration

No overlap shall exist between modules.

---

# 16. Environment Composition

Modules are composed only by Terraform environments.

Example:

Sandbox

↓

Rule Groups

↓

Firewall Policy

↓

Firewall

Modules shall remain unaware of consuming environments.

---

# 17. Outputs

Each module shall expose only information required by downstream consumers.

Rule Group Module

Outputs:

- Rule Group IDs
- Rule Group ARNs
- Rule Group Names

Firewall Policy Module

Outputs:

- Policy ID
- Policy ARN

Firewall Module

Outputs:

- Firewall ID
- Firewall ARN
- Endpoint IDs
- Sync States
- Firewall Status

---

# 18. Testing Strategy

Each module shall maintain an independent validation environment.

Required validation:

- terraform fmt
- terraform init
- terraform validate
- terraform plan
- terraform apply
- terraform destroy

Module tests shall validate module behaviour rather than complete architectures.

Sandbox provides integration testing across modules.

---

# 19. Future Enhancements

The design intentionally accommodates future AWS Network Firewall capabilities.

Potential future enhancements include:

- TLS Inspection Configuration
- AWS Firewall Manager integration
- Centralized enterprise rule libraries
- Managed rule catalog support
- Cross-account policy deployment
- Organization-wide firewall governance

Future enhancements shall extend existing interfaces without introducing breaking changes.

---

# 20. Design Constraints

The module suite shall comply with:

- Architecture Principles
- Terraform Module Development Standard
- Module Testing Standard
- Diagram Development Standard

No implementation shall violate these governing standards.

---

# 21. Success Criteria

The module suite shall be considered complete when:

- Every AWS Network Firewall capability is represented.
- All variables are strongly typed.
- Public interfaces are stable.
- Each module is independently testable.
- Each module is enterprise-pluggable.
- Documentation is complete.
- Sandbox integration succeeds.
- The module suite aligns with AWS Well-Architected Framework guidance.

---

# 22. Guiding Principle

The AWS Network Firewall Module Suite is intended to be a long-lived engineering asset.

The preferred implementation is one that:

- Mirrors AWS architecture.
- Minimizes abstraction.
- Maximizes enterprise reuse.
- Preserves stable public interfaces.
- Encourages composition.
- Remains understandable by engineers familiar with AWS Network Firewall.

Every design decision shall favor long-term maintainability over short-term implementation convenience.