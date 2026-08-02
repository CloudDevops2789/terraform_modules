# Terraform Module Development Standard (TMDS)
**Version:** 1.0
**Status:** Repository Standard (Normative)
**Applies To:** All Terraform modules under `terraform/modules`
**Owner:** Cyber Security Resilience and Recovery Team

# 1. Purpose

This document defines the mandatory engineering standards for all Terraform modules contained within this repository.

The objective is to ensure every module is:

- Enterprise-ready
- Reusable
- Predictable
- Maintainable
- Independently testable
- Suitable for direct deployment into production environments

Compliance with this standard is mandatory for all new modules and for future enhancements to existing modules.

---

# 2. Design Objectives

Every module shall:

- Own a single AWS capability.
- Expose a stable public interface.
- Be composable with other modules.
- Avoid environment-specific assumptions.
- Support enterprise deployment patterns.
- Follow AWS Well-Architected Framework principles.
- Minimize operational complexity.

Modules shall prioritize readability and long-term maintainability over implementation brevity.

---

# 3. Module Responsibility

Each module shall own only the AWS resources implied by its purpose.

Example:

A Client VPN module owns:

- Client VPN Endpoint
- Network Associations
- Authorization Rules
- VPN Logging Configuration

It shall not own:

- VPC
- Route Tables
- Security Groups
- IAM Roles
- Certificates

Supporting infrastructure shall be supplied by the consuming environment.

---

# 4. Separation of Concerns

Infrastructure modules shall provision infrastructure.

They shall not perform orchestration.

Examples of orchestration include:

- Routing relationships
- Cross-module wiring
- Environment composition
- Deployment sequencing

These responsibilities belong to Terraform environments.

---

# 5. Public Module Interface

The module interface represents a public contract.

Variable names shall remain stable.

Output names shall remain stable.

Breaking interface changes shall be avoided.

Where additional functionality is required, extend the existing interface instead of replacing it.

---

# 6. Variable Standards

Variables shall:

- Use explicit Terraform types.
- Include descriptions.
- Use meaningful names.
- Minimize required inputs where practical.

Permitted types include:

- string
- number
- bool
- object(...)
- map(...)
- list(...)
- set(...)
- optional(...)

The use of `any` is prohibited unless the AWS provider exposes a structure that cannot reasonably be represented using Terraform's type system.

---

# 7. Enterprise Compatibility

Modules shall support enterprise deployment patterns.

Where practical, modules shall support both:

- Creating new resources
- Consuming existing resources

Examples include:

- Existing IAM Roles
- Existing KMS Keys
- Existing ACM Certificates
- Existing CloudWatch Log Groups
- Existing Network Firewall Rule Groups

The module shall not require enterprise resources to be recreated.

---

# 8. Resource Ownership

Modules shall own AWS resources.

Modules shall not own enterprise configuration.

Examples:

Network Firewall module creates:

- Firewall
- Firewall Policy
- Rule Groups
- Logging Configuration

It shall not create:

- Firewall VPC
- Firewall Subnets
- Route Tables
- Transit Gateway

Infrastructure placement remains the responsibility of the consuming environment.

---

# 9. Business Logic

Business logic shall reside within `locals.tf`.

Typical examples include:

- Input normalization
- Object merging
- Default assignment
- Priority calculation
- Conditional evaluation
- Derived values

Terraform resources shall remain declarative.

Resources should consume local values rather than implement complex expressions inline.

---

# 10.Engineering rule

Complex public APIs shall be developed and reviewed incrementally. Public interfaces should be finalized and validated before implementation resources are written. Large variable schemas should be introduced in logical sections rather than as a single monolithic change to improve reviewability and reduce the risk of API defects.

# 11. Resource Files

Resources shall be grouped by responsibility.

Example:

network-firewall/

- firewall.tf
- firewall-policy.tf
- rule-groups.tf
- logging.tf

Avoid monolithic `main.tf` files.

---

# 12. Naming Standards

Modules shall not enforce enterprise naming conventions.

Hardcoded names are prohibited.

Examples include:

- Resource names
- Bucket names
- Log Group names
- IAM Role names
- Security Group names

Names shall be supplied by the consuming environment.

---

# 13. Outputs

Outputs shall expose information required by downstream consumers.

Typical outputs include:

- IDs
- ARNs
- DNS Names
- Endpoint IDs
- Status

Outputs shall not expose unnecessary provider attributes.

---

# 14. Documentation

Every module shall contain:

- README.md
- versions.tf
- variables.tf
- outputs.tf

README.md shall document:

- Purpose
- Resources created
- Inputs
- Outputs
- Dependencies
- Supporting infrastructure
- Enterprise considerations
- Example usage

Documentation shall explain design decisions rather than merely describe Terraform syntax.

Complex public APIs shall be developed and reviewed incrementally. Public interfaces should be finalized and validated before implementation resources are written. Large variable schemas should be introduced in logical sections rather than as a single monolithic change to improve reviewability and reduce the risk of API defects.
---

# 15. Code Documentation

Comments are mandatory where they improve understanding.

Comments shall explain:

WHY

rather than

WHAT

Poor:

# Creates a VPC

Good:

# Dedicated VPC used to isolate inspection workloads from recovery workloads.

Redundant comments shall be avoided.

---

# 16. Formatting

Terraform code shall:

- Follow `terraform fmt`.
- Use consistent indentation.
- Avoid unnecessary blank lines.
- Group related resources.
- Maintain logical ordering.

Readability shall take precedence over compactness.

---

# 17. Dependency Management

Modules shall not assume:

- AWS Regions
- Availability Zones
- CIDR allocations
- Naming conventions
- Existing infrastructure

All external dependencies shall be supplied as inputs.

---

# 18. Error Prevention

Modules shall prevent invalid configuration whenever practical.

Examples include:

- Variable validation
- Strong typing
- Sensible defaults
- Computed locals

Terraform validation errors are preferred over AWS API errors.

---

# 19. Testing Standard

Every module shall include a dedicated validation environment located under:

terraform/environments/module-tests/

Each validation environment shall contain:

- backend.tf
- provider.tf
- versions.tf
- locals.tf
- variables.tf
- outputs.tf
- terraform.tfvars.example
- README.md

Supporting infrastructure shall be limited to the minimum required to exercise the module.

The module under test is the focus.

Supporting resources are implementation dependencies only.

---

# 20. Validation Requirements

Every module shall successfully complete:

terraform fmt

terraform init

terraform validate

terraform plan

terraform apply

terraform destroy

without manual intervention.

Validation environments shall support a complete deployment lifecycle using a single Terraform root module.

---

# 21. Enterprise Readiness Checklist

Before a module is considered complete, verify:

- Single responsibility
- Stable public API
- Strongly typed variables
- Enterprise-compatible inputs
- Existing resource support where applicable
- Business logic centralized in locals.tf
- Minimal resource complexity
- Useful outputs
- Complete documentation
- Dedicated validation environment
- Successful validation lifecycle
- Compliance with AWS Well-Architected Framework
- Compliance with Architecture Principles
- Compliance with this standard

Modules failing any mandatory requirement shall not be considered production-ready.

---

# 22. Guiding Principle

Terraform modules are long-lived engineering assets.

Design decisions shall favor:

- Stability
- Predictability
- Simplicity
- Reusability
- Enterprise compatibility

over short-term implementation convenience.

The preferred solution is the one that can be confidently adopted by a large enterprise without requiring modification.