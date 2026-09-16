# Inspection Stack

## Purpose

The Inspection stack is the independently managed network-security lifecycle for
the AWS Isolated Recovery Environment.

It consumes Platform-owned network topology and Persistent-owned logging
encryption and is designed to own AWS Network Firewall, firewall policy,
inspection rules, logging, and firewall-dependent routing.

## Ownership boundary

Platform owns:

- Inspection VPC;
- Network Firewall and Transit Gateway subnets;
- Transit Gateway;
- Transit Gateway VPC attachments;
- Transit Gateway route tables;
- ordinary VPC-to-Transit-Gateway routing;
- approved directional connectivity exposed through `inspection_contract`.

Inspection owns after state migration:

- AWS Network Firewall;
- Network Firewall stateful rule groups;
- Network Firewall policy;
- Network Firewall CloudWatch logging;
- firewall log groups;
- routes whose next hop depends on Network Firewall endpoint IDs;
- TGW routes that steer approved traffic through the Inspection attachment.

Persistent owns the optional KMS key used for Network Firewall log encryption.

## Dependency flow

Platform:

`Platform state -> inspection_contract -> AAP -> var.inspection_contract`

Persistent:

`Persistent state -> network_firewall_logging_kms_key_arn -> AAP -> var.persistent_resources`

Git-controlled Inspection configuration:

`common-tags.tfvars + inspection.tfvars -> naming / tags / firewall rules / logging`

Upstream AWS identifiers must not be manually copied into `inspection.tfvars`.

## Current ownership

The Inspection stack owns the AWS Network Firewall lifecycle, including firewall
policy, rule groups, firewall logging, and routes whose next hop depends on
Network Firewall endpoints.

Platform owns the underlying Inspection VPC, subnets, Transit Gateway topology,
and the `inspection_contract` consumed by this stack.

## Firewall routing boundary

Platform continues to manage ordinary spoke VPC route-table routes toward the
Transit Gateway.

Inspection manages only firewall-dependent routes:

1. Inspection TGW subnet route tables -> same-AZ Network Firewall endpoints.
2. Network Firewall subnet route tables -> Transit Gateway.
3. source-domain TGW route tables -> Inspection VPC attachment.

This keeps base network topology independent from the firewall service lifecycle.

## Operational enablement

Inspection does not require a separate Terraform `enabled` switch.

For the current workflow model:

- firewall architecture: Platform is configured for firewall topology and the
  Inspection Job Template is chained;
- bypass architecture: Platform is configured for bypass topology and the
  Inspection Job Template is omitted.

Git network configuration and workflow selection must remain consistent.
