# VPN Test Environment

This deployable root exercises the repository's VPN composition. It uses the
same canonical enterprise-tag interface and local collaboration model as the
sandbox root.

Copy `terraform.tfvars.example` to `terraform.tfvars` and
`backend.hcl.example` to `backend.hcl`, then replace only the local placeholder
values. Both local files are ignored by Git and must not be committed.

```bash
terraform init -backend-config=backend.hcl
terraform fmt -check
terraform validate
terraform plan -var-file=terraform.tfvars
```

AWS credentials must come from an approved authentication mechanism. CI/CD
must provide its own variable and backend configuration. Check `git status`
before committing and exclude local paths, credentials, plans, state, and
logs.
