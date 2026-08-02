# Diagram Development Standard (DDS)
**Version:** 1.0
**Status:** Repository Standard (Normative)
**Applies To:** All architecture diagrams contained within this repository
**Owner:** Cyber Security Resilience and Recovery Team

# 1. Purpose

This document defines the mandatory standards governing the creation, maintenance, and evolution of architecture diagrams within this repository.

Architecture diagrams are engineering artifacts.

They communicate system design, trust boundaries, operational responsibilities, and security controls.

Every diagram shall accurately represent the implemented architecture and remain consistent with the Terraform modules and Architecture Principles defined within this repository.

---

# 2. Objectives

Architecture diagrams shall:

- Accurately represent the deployed architecture.
- Communicate architectural intent.
- Remain technically correct.
- Be visually consistent.
- Support Architecture Review Board (ARB) reviews.
- Support operational documentation.
- Support future engineering work.

Diagrams shall prioritize clarity over artistic presentation.

---

# 3. Source of Truth

Terraform remains the implementation source of truth.

Architecture diagrams remain the design source of truth.

Whenever discrepancies exist between diagrams and Terraform, the discrepancy shall be investigated and resolved.

Architecture diagrams shall never intentionally diverge from implemented infrastructure.

---

# 4. Diagram Types

The repository recognizes four diagram categories.

## High-Level Design (HLD)

Audience:

- Architecture Review Board
- Enterprise Architects
- Security Architects
- Technical Leadership

Purpose:

Describe architecture.

Avoid implementation detail.

---

## Low-Level Design (LLD)

Audience:

- Cloud Engineers
- Platform Engineers
- Operations

Purpose:

Describe implementation.

Include routing, subnet segmentation, IAM relationships, logging, inspection paths, endpoint placement, and operational controls.

---

## Deployment Diagrams

Audience:

- Infrastructure Engineers

Purpose:

Illustrate deployment topology.

Reflect Terraform implementation.

---

## Operational Diagrams

Audience:

- Operations
- Incident Response
- Support

Purpose:

Illustrate operational workflows.

Examples include:

- Backup Flow
- Recovery Flow
- Restore Process
- Validation Pipeline
- Disaster Recovery Runbooks

---

# 5. Diagram Philosophy

Diagrams communicate architecture.

They do not replace documentation.

Avoid excessive detail.

Avoid configuration values.

Avoid implementation-specific settings unless the diagram is specifically an LLD.

Architecture should be understandable within a few minutes.

---

# 6. Visual Consistency

All diagrams shall maintain a consistent visual language.

Use:

- AWS Architecture Icons
- AWS colour palette
- Consistent typography
- Consistent spacing
- Consistent connector styles
- Consistent alignment

Do not mix icon libraries.

Do not substitute unofficial AWS icons.

---

# 7. AWS Architecture Icons

Only official AWS Architecture Icons shall be used.

Icons shall:

- Maintain aspect ratio.
- Maintain consistent sizing.
- Remain unmodified.
- Remain visually sharp.

Distorted or stretched icons are prohibited.

---

# 8. Resolution

Architecture diagrams shall be suitable for:

- Architecture documentation
- A3 printing
- Technical presentations
- High-resolution zoom

Preferred formats:

- SVG
- Draw.io XML
- High-resolution PNG

Raster diagrams shall remain readable at 300–400% zoom.

---

# 9. Layout

Diagrams shall use logical left-to-right or top-to-bottom information flow.

Avoid unnecessary crossing connectors.

Maintain consistent whitespace.

Maintain consistent margins.

Align resources to a common grid.

Visual balance shall be preserved.

---

# 10. Trust Boundaries

Trust boundaries shall be explicitly represented.

Examples include:

- Recovery Access
- Core Recovery
- Inspection
- Protected Data

Trust boundaries shall not be implied.

They shall be visually identifiable.

Trust boundaries shall not overlap.

---

# 11. Networking

Network flow shall accurately represent implemented routing.

Traffic direction shall be explicit.

Ingress and egress paths shall be distinguishable.

Transit Gateway relationships shall accurately reflect routing domains.

Inspection paths shall accurately represent architectural intent.

---

# 12. Security Representation

Security controls shall be represented using architecture rather than excessive annotation.

Examples:

- VPC boundaries
- AWS Network Firewall
- Client VPN
- Site-to-Site VPN
- PrivateLink
- IAM separation

Avoid excessive implementation notes within High-Level Designs.

---

# 13. High-Level Design Principles

High-Level Design diagrams shall describe:

- Major AWS services
- Trust boundaries
- Network topology
- Security zones
- Data flow
- Administrative flow
- Recovery workflow

High-Level Designs shall not include:

- Security Group rules
- Route table entries
- IAM policies
- NACL rules
- Terraform variables
- Resource IDs

---

# 14. Low-Level Design Principles

Low-Level Designs may include:

- Route Tables
- Security Groups
- NACL segmentation
- TGW routing
- Firewall routing
- Endpoint policies
- IAM relationships
- Logging
- Monitoring
- Operational controls

Implementation details belong only in LLD documentation.

---

# 15. Architectural Stability

Architecture diagrams shall evolve conservatively.

Avoid redesigning diagrams unnecessarily.

When architecture is approved, subsequent revisions should focus on:

- Corrections
- Clarifications
- Enterprise hardening
- Additional documentation

Avoid architectural churn.

---

# 16. Change Management

Architecture changes shall preserve visual continuity.

Minor architectural changes shall not result in complete diagram redesign.

Visual familiarity improves maintainability and review efficiency.

---

# 17. Annotation Standards

Annotations shall:

- Be concise.
- Explain intent.
- Avoid excessive text.

Prefer architecture over annotation.

If an idea can be communicated through placement rather than text, placement should be preferred.

---

# 18. Colour Usage

Colour shall communicate architectural meaning.

Do not use colour solely for decoration.

Examples include:

- Trust boundaries
- Security zones
- Data flow
- Administrative flow

Colour usage shall remain consistent throughout the repository.

---

# 19. Diagram Review

Every architecture diagram shall be reviewed against:

- Architecture Principles
- Terraform Module Development Standard
- Module Testing Standard
- AWS Well-Architected Framework
- AWS Architecture Best Practices

Architecture diagrams shall remain technically accurate.

---

# 20. Enterprise Readiness

Production architecture diagrams shall clearly communicate:

- Trust boundaries
- Security controls
- Administrative plane
- Data plane
- Inspection flow
- Backup flow
- Recovery flow
- Network segmentation

Enterprise reviewers shall understand the architecture without requiring supplementary explanation.

---

# 21. Diagram Ownership

Architecture diagrams are engineering documentation.

Diagrams shall be version controlled.

Diagrams shall evolve together with Terraform.

Documentation updates shall accompany architectural changes.

---

# 22. Guiding Principle

Architecture diagrams are communication tools.

The preferred diagram is one that allows an experienced cloud architect to understand:

- What exists.
- Why it exists.
- How trust is established.
- How traffic flows.
- Where security boundaries exist.

within a few minutes of inspection.

Clarity, consistency, and technical correctness shall always take precedence over visual complexity or artistic presentation.