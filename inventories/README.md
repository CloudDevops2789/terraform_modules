# AAP SCM Inventories

AAP environment bindings are sourced from a Git-controlled inventory rather
than copied into every Job Template.

`example/` is customer-neutral and must not be selected by a real AAP Job
Template. Copy its structure into the private deployment-configuration
repository, replace the placeholders, and configure an AAP SCM inventory source
to use that environment's `hosts.yml`.

The environment inventory owns:

- target environment;
- approved AssumeRole binding and expected account guard;
- deployment and backend Regions;
- backend bucket;
- Persistent Resources contract source and approved external references; and
- workload target membership and connection metadata when operating-system
  automation is required.

The `localhost` host remains the control-plane target for Terraform, AWS API,
directory infrastructure, certificate, and other controller-local automation.

The `workload_targets` group is reserved for Windows and Linux EC2 workloads
that require operating-system automation such as directory bootstrap. The
public inventory intentionally defines the group without static hosts.

Real workload targets should be supplied by the approved AAP/private inventory
source or runtime inventory integration. Per-host connection metadata may
include values such as:

- `ansible_host`;
- `ansible_connection`;
- `ansible_user`; and
- transport-specific non-secret settings.

Credentials, passwords, SSH private keys, WinRM passwords, domain-join
passwords, access keys, and protected tokens must not be stored in these
inventories.

Job Templates own only lifecycle/runtime intent and the variables explicitly
allowed by the target playbook.

Stable infrastructure settings such as Client VPN enablement, Network Firewall
mode, topology, tags, and Persistent capability switches remain in tracked
Terraform `.tfvars` files.
