# Architecture Principles

## Purpose

This repository contains enterprise-grade Terraform modules and reference environments for building an AWS Isolated Recovery Environment (IRE).

The objective is to produce reusable Infrastructure-as-Code that can be deployed directly into enterprise environments while remaining fully testable in a home lab.

The home lab exists to validate enterprise modules.

The enterprise architecture is the primary design target.

---

# Core Design Philosophy

The following principles govern every module, environment, and architectural decision in this repository.

These principles are considered authoritative and should not be changed without architectural review.

## Enterprise First

Every module must be suitable for direct use in enterprise environments.

A home lab should consume enterprise modules.

Enterprise modules should never be simplified purely for home-lab convenience.

If a feature is required by enterprise customers, it belongs in the module.

If a feature is only required for home-lab testing, it belongs in the consuming environment.

---

## Simplicity Over Cleverness

Prefer simple, readable Terraform.

Avoid unnecessary abstraction.

Avoid deeply nested logic.

Avoid magic.

A future engineer should understand a module within a few minutes.

---

## Separation of Concerns

Each module owns one responsibility.

Examples:

- VPC module owns VPC resources.
- Client VPN module owns Client VPN resources.
- Network Firewall module owns Network Firewall resources.
- Security Group module owns Security Groups.

Modules must never create infrastructure outside their defined responsibility.

---

## Composition Over Monolithic Design

Infrastructure is composed by environments.

Modules should be small building blocks.

Example:

Sandbox
│
├── VPC
├── Security Group
├── EC2
├── Client VPN
├── Network Firewall
└── Backup

The environment composes modules.

Modules do not compose environments.

---

# Enterprise Compatibility

Every reusable enterprise dependency should support both creation and consumption.

Whenever practical, modules should support:

- Create new resource
- Use existing enterprise resource

Examples include:

- IAM Roles
- KMS Keys
- ACM Certificates
- Network Firewall Rule Groups
- CloudWatch Log Groups

This allows the same module to be used in greenfield and brownfield deployments.

---

# Resource Ownership

A module owns only the AWS resources implied by its name.

Examples

## Client VPN

Creates:

- Client VPN Endpoint
- Network Associations
- Authorization Rules
- Logging Configuration

Does not create:

- VPC
- Route Tables
- Security Groups
- ACM Certificates

---

## Network Firewall

Creates:

- Firewall
- Firewall Policy
- Rule Groups
- Logging Configuration

Does not create:

- VPC
- Subnets
- Route Tables
- Transit Gateway
- CloudWatch Log Groups

---

## VPC

Creates:

- VPC
- Subnets
- Route Tables
- Internet Gateway
- NAT Gateway (if enabled)

Does not create:

- EC2
- Security Groups
- Client VPN
- Network Firewall

---

# Infrastructure Relationships

Relationships between infrastructure components belong to environments.

Examples:

- Route Tables
- Transit Gateway Attachments
- Security Group References
- Subnet Placement
- VPC Associations

Modules expose outputs.

Environments wire modules together.

---

# Module API Design

Public module interfaces should remain stable.

Avoid breaking variable names.

Avoid changing output names.

Prefer extending APIs over replacing them.

A stable module API is more valuable than a perfect one.

---

# Strong Typing

Terraform variables should be strongly typed.

Use:

- object(...)
- map(...)
- list(...)
- optional(...)

Avoid:

- any

unless the AWS provider makes strong typing impossible.

Terraform validation should detect configuration errors before AWS does.

---

# Logic Placement

Business logic belongs in locals.tf.

Examples include:

- Input normalization
- Object merging
- Default values
- Rule priority assignment
- Computed relationships

Terraform resources should remain declarative.

Resources should consume locals rather than perform complex calculations inline.

---

# Naming

Modules should never assume enterprise naming standards.

Names should be provided by the consuming environment.

Avoid hardcoded:

- prefixes
- suffixes
- log group names
- bucket names
- resource names

---

# Outputs

Expose only outputs that consumers require.

Typical outputs include:

- IDs
- ARNs
- Endpoint IDs
- Status
- DNS Names

Avoid exposing every provider attribute.

---

# Documentation

Every module must contain:

- README.md
- versions.tf
- variables.tf
- outputs.tf

Comments should explain:

WHY

not merely

WHAT

Documentation should enable future maintainers to understand design decisions.

---

# Code Style

Modules should follow a consistent layout.

Example

modules/
    module-name/
        versions.tf
        locals.tf
        variables.tf
        outputs.tf
        resource-a.tf
        resource-b.tf
        README.md

Avoid monolithic main.tf files.

Separate resources by responsibility.

Avoid unnecessary blank lines.

Maintain consistent formatting.

---

# Testing Philosophy

Every module must have an isolated validation environment.

Location

terraform/
    environments/
        module-tests/
            module-name/

Module tests should include only the supporting infrastructure required to exercise the module.

Supporting infrastructure is not under test.

The target module is under test.

Each module test should support:

- terraform fmt
- terraform init
- terraform validate
- terraform plan
- terraform apply
- terraform destroy

using a single Terraform root module.

Each module test should include:

- backend.tf
- provider.tf
- versions.tf
- locals.tf
- variables.tf
- outputs.tf
- terraform.tfvars.example
- README.md

---

# Architecture Principles

The reference architecture follows four trust boundaries.

Recovery Access

Administrative plane only.

Contains:

- Client VPN
- Authentication
- Management endpoints
- Break-glass access

Contains no workloads.

---

Core Recovery

Recovery operations plane.

Contains:

- Recovery tooling
- Automation
- Validation
- Backup ingestion
- Malware scanning
- Approval workflow
- Island Enterprise Browser

Site-to-Site VPN terminates here.

---

Inspection

Security enforcement plane.

Contains:

- AWS Network Firewall
- Inspection routing
- Firewall endpoints

Contains no workloads.

---

Protected Data

Recovery target plane.

Contains:

- Approved recovery content
- Recovery workloads
- Databases
- Storage

Contains no backup ingestion.

Contains no malware scanning.

---

# Zero Trust

The architecture follows Zero Trust principles.

Identity is verified before access.

Administrative traffic is separated from data traffic.

Recovery Access has no route to Protected Data.

Inspection is centralized.

Least privilege is applied throughout.

Every trust boundary should minimize blast radius.

---

# Future Module Checklist

Before a module is considered complete, verify:

- Does the module own only its intended AWS resources?
- Is the public API stable?
- Are variables strongly typed?
- Are comments explaining WHY?
- Does the module support enterprise reuse?
- Can existing enterprise resources be consumed?
- Does complex logic live in locals.tf?
- Are outputs useful and minimal?
- Does the module include documentation?
- Does the module include module-tests?
- Can the module be deployed independently?
- Does the module align with AWS Well-Architected principles?
- Does the module comply with this Architecture Principles document?

If any answer is No, the module is not considered production-ready.

---

# Guiding Principle

Every change to this repository should make the modules:

- More reusable
- More maintainable
- More predictable
- More enterprise-ready

without making them unnecessarily complex.

When in doubt, choose the design that a large enterprise would confidently deploy in production.