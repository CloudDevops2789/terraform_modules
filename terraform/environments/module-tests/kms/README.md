# Purpose

Validates that the `kms` module (`terraform/modules/kms`) deploys
successfully: a customer managed KMS key with its key policy and alias.

# Module Under Test

`terraform/modules/kms`

This test exercises key creation with the module's default lifecycle
settings (key rotation enabled, a 30-day deletion window) and its default
key-administration bootstrap, where the module grants administrative
access to whichever identity runs `terraform apply` because no explicit
`key_administrators` are supplied.

# Supporting Resources

None. The kms module is fully self-contained: it resolves the calling AWS
identity itself via a data source rather than requiring the caller to
supply administrator ARNs, and it builds its own key policy internally.
Everything this environment creates (`module.kms`) is the module under
test.

# Deployment

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init -input=false -reconfigure -backend-config=backend.hcl
terraform plan -input=false
terraform apply -input=false
```

# Destroy

```bash
terraform destroy -input=false
```

The KMS key enters AWS's 30-day pending-deletion window rather than
being deleted immediately - this is normal AWS behavior for
`aws_kms_key`, not a defect in this test. The alias is removed right
away.

# Expected Outcome

`terraform apply` completes with no errors and reports one KMS key and one
KMS alias. `key_id`, `key_arn`, and `alias_name` are all populated
outputs.

# Notes

This environment has no supporting resources - the kms module is
self-contained. Everything created here is the module under test itself,
so there is nothing to distinguish from "not under test" in this case.
