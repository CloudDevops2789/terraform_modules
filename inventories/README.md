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
- backend bucket; and
- Persistent Resources contract source and approved external references.

Job Templates own only stack selection, lifecycle intent, destroy gates, and
the allowlisted `terraform_variables` map.

Stable infrastructure settings such as Client VPN enablement, Network Firewall
mode, topology, tags, and Persistent capability switches remain in tracked
Terraform `.tfvars` files.

Credentials, passwords, private keys, access keys, and protected tokens must
not be stored in these inventories.
