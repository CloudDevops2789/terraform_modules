# KMS module

This module creates a customer-managed AWS KMS key and optional alias from
caller-supplied policy, rotation, deletion-window and tagging inputs.

The module is reusable and contains no environment, account, role or customer
defaults. The consuming lifecycle stack owns policy construction and decides
whether the key is persistent or disposable.

## IRE ownership

The Persistent stack can use this module for optional Network Firewall
CloudWatch Logs encryption. Existing AWS names containing the historical
`foundation` prefix are retained until a separately approved naming migration.

## Safety

- KMS policy changes can remove administrative or workload access.
- Shortening deletion windows or destroying a key can make encrypted evidence
  unrecoverable.
- Review aliases, administrators, service principals and grants in the complete
  plan.
- Do not replace a key for cosmetic naming.
- Persistent-stack destroy remains controlled through AAP guardrails.

The matching validation composition is under
`terraform/environments/module-tests/kms`.
