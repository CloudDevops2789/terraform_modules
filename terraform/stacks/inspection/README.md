# Inspection Stack

## Purpose

The Inspection stack is the independently managed network-security lifecycle
for the AWS Isolated Recovery Environment.

It consumes Platform-owned topology and, once the ownership migration is
completed, will manage AWS Network Firewall and the routing that depends on
firewall endpoint IDs.

## Ownership boundary

Platform owns:

- Inspection VPC;
- Network Firewall and Transit Gateway subnets;
- Transit Gateway;
- Transit Gateway VPC attachments;
- Transit Gateway route tables;
- base network topology.

Inspection owns:

- AWS Network Firewall;
- Network Firewall rule groups;
- Network Firewall policy;
- Network Firewall logging;
- CloudWatch log groups used by Network Firewall;
- VPC and Transit Gateway routes whose correctness depends on firewall
  endpoint IDs.

Persistent owns the optional KMS key used for Network Firewall log encryption.

## Dependency flow

Platform:

`Platform state -> inspection_contract -> AAP -> var.inspection_contract`

Persistent:

`Persistent state -> network_firewall_logging_kms_key_arn -> AAP -> var.persistent_resources`

Do not manually copy upstream AWS identifiers into `inspection.tfvars`.

## Current state

This root is initially a non-owning lifecycle skeleton. It intentionally creates
no AWS resources.

Existing Network Firewall resources remain owned by Platform until a separately
validated state-ownership migration is performed.

Do not apply this root as a mechanism for moving existing resources between
states.
