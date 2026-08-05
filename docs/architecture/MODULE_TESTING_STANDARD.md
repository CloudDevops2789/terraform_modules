# Module Testing Standard (MTS)
**Version:** 1.0
**Status:** Repository Standard (Normative)
**Applies To:** All Terraform module validation environments under `terraform/environments/module-tests`
**Owner:** Cyber Security Resilience and Recovery Team

# 1. Purpose

This document defines the mandatory testing standard for all Terraform modules contained within this repository.

The objective is to ensure every module can be independently validated before being consumed by higher-level environments such as Sandbox or future production deployments.

Module testing verifies module behaviour, not complete infrastructure deployments.

Every module shall include an isolated validation environment.

---

# 2. Objectives

Module validation shall verify:

- Terraform syntax
- Variable validation
- Resource creation
- Resource destruction
- Output generation
- Module interoperability
- Enterprise deployment readiness

Validation environments shall remain deterministic, repeatable, and self-contained.

---

# 3. Testing Philosophy

Module tests validate one module.

Supporting infrastructure exists only to satisfy the module's dependencies.

Supporting infrastructure is not under test.

Example:

Client VPN module

Supporting resources:

- VPC
- Subnet
- Security Group
- ACM Certificates

Module under test:

- Client VPN Endpoint
- Associations
- Authorization Rules
- Logging

The objective is to validate the Client VPN module, not networking.

---

# 4. Directory Structure

Every module shall contain a dedicated validation environment.

Example:

terraform/
└── environments/
    └── module-tests/
        └── client-vpn/
            ├── backend.tf
            ├── provider.tf
            ├── versions.tf
            ├── variables.tf
            ├── locals.tf
            ├── outputs.tf
            ├── terraform.tfvars.example
            ├── README.md
            ├── networking.tf
            ├── security.tf
            └── client-vpn.tf

The validation environment shall exist independently of Sandbox.

---

# 5. Supporting Infrastructure

Supporting infrastructure shall be limited to the minimum required to deploy the module.

Examples include:

- VPC
- Subnets
- Security Groups
- IAM Roles
- KMS Keys
- ACM Certificates
- CloudWatch Log Groups

Supporting resources shall not introduce unnecessary complexity.

Supporting resources shall not duplicate production architecture.

---

# 6. Enterprise Compatibility

Validation environments shall mirror enterprise deployment patterns whenever practical.

Examples:

Use existing enterprise interfaces.

Support externally managed resources.

Follow enterprise naming conventions.

Avoid hardcoded assumptions.

The objective is to demonstrate that the module can be directly consumed by enterprise environments.

---

# 7. Test Independence

Each validation environment shall maintain its own Terraform state.

Each environment shall define its own backend configuration.

Example:

module-tests/
├── vpc/
├── ec2/
├── client-vpn/
├── network-firewall/
└── backup-vault/

Each environment shall use an independent state file.

Example:

module-tests/client-vpn/terraform.tfstate

module-tests/network-firewall/terraform.tfstate

Module tests shall never share Terraform state.

---

# 8. Validation Lifecycle

Every validation environment shall successfully complete the following lifecycle.

terraform fmt

terraform init

terraform validate

terraform plan

terraform apply

terraform destroy

Successful completion of this lifecycle is mandatory before a module is considered production-ready.

---

# 9. Validation Automation

A repository-level validation script shall execute the validation lifecycle for every module test.

Example:

terraform/environments/module-tests/validate.sh

The validation script shall:

- Discover module-test directories automatically.
- Execute validation sequentially.
- Continue executing remaining module tests after individual failures.
- Produce a summary report.
- Return a non-zero exit code when failures occur.

The validation script shall not modify Terraform configuration.

---

# 10. Backend Configuration

Every validation environment shall maintain its own backend configuration.

Backend keys shall follow a consistent convention.

Example:

module-tests/vpc/terraform.tfstate

module-tests/client-vpn/terraform.tfstate

module-tests/network-firewall/terraform.tfstate

State isolation is mandatory.

---

# 11. Variables

Validation environments shall expose only variables required for testing.

Variables shall:

- Be strongly typed.
- Include descriptions.
- Include sensible defaults where practical.

Validation environments shall include:

terraform.tfvars.example

The example file shall demonstrate a complete deployment configuration.

---

# 12. Locals

Static configuration shall reside within locals.tf.

Examples include:

- Names
- CIDRs
- Ports
- Tags
- Test configuration

Computed values shall also reside within locals.tf where appropriate.

Terraform resources shall remain declarative.

---

# 13. Documentation

Every validation environment shall contain a README.md.

The README shall document:

- Module under test
- Purpose
- Supporting infrastructure
- Resources created
- Validation procedure
- Expected outputs
- Known limitations
- Enterprise considerations

Documentation shall explain why supporting infrastructure exists.

---

# 14. Resource Scope

Validation environments shall create only resources required for testing.

Validation environments shall not attempt to recreate production environments.

Avoid:

- Multiple VPCs
- Complex routing
- Large IAM hierarchies
- High availability beyond module requirements

Validation environments should remain intentionally minimal.

---

# 15. Resource Cleanup

Validation environments shall support complete cleanup.

terraform destroy shall remove all resources created by the validation environment.

Manual cleanup shall not be required.

Temporary resources shall not remain after destruction.

---

# 16. Naming Standards

Validation resources shall clearly identify themselves.

Example:

module-test-client-vpn

module-test-network-firewall

module-test-backup-vault

This prevents confusion with Sandbox or production resources.

---

# 17. Tags

Validation resources shall include standard repository tags.

Example:

```hcl
org_it_cost_center       = "replace-with-approved-cost-center"
org_department           = "replace-with-approved-department"
org_cmdb_calculated_app  = "replace-with-approved-cmdb-application"
org_business_criticality = "replace-with-approved-criticality"
org_environment          = "replace-with-approved-environment"
org_data_classification  = "replace-with-approved-data-classification"
org_project_name         = "replace-with-approved-project-name"
org_managed_by           = "Terraform"

org_additional_tags = {
  org_tested_module = "client-vpn"
}
```

Additional tags may be added where appropriate.

---

# 18. Module Isolation

Module tests shall not reference Sandbox resources.

Module tests shall not depend on Sandbox state.

Module tests shall not consume Sandbox outputs.

Every validation environment shall be deployable independently.

---

# 19. Success Criteria

A module shall be considered validated when:

- Terraform formatting succeeds.
- Initialization succeeds.
- Validation succeeds.
- Planning succeeds.
- Apply succeeds.
- Outputs are generated correctly.
- Destroy succeeds.
- No manual intervention is required.

---

# 20. Future Requirements

As new modules are introduced, corresponding validation environments shall be created before the module is considered complete.

Module development and module validation are inseparable activities.

A module without a validation environment shall not be considered production-ready.

---

# 21. Guiding Principle

Module tests exist to validate reusable infrastructure modules, not to simulate production environments.

Validation environments should remain:

- Small
- Deterministic
- Repeatable
- Self-contained
- Easy to understand
- Easy to destroy

The preferred validation environment is the simplest environment capable of exercising every feature owned by the module and demonstrating that the module is ready for enterprise consumption.
