# Network Firewall Policy Module Test
## Purpose
This independent Terraform root validates `terraform/modules/network-firewall-policy`.
## Prerequisite
The repository must already contain the validated `terraform/modules/network-firewall-rule-group` module.
## Coverage
The test creates two supporting rule groups and two firewall policies.
The strict-order policy validates:
- Policy-level `HOME_NET`
- Strict stateful rule order
- Stateful default actions
- TCP idle timeout
- Stream exception policy
- Stateful and stateless rule group references
- Unique priorities
- Stateless custom CloudWatch metric action
The second policy validates the minimal default-action-order path.
## Backend
The S3 state key is:
```text
module-tests/network-firewall-policy/terraform.tfstate
```
Supply shared backend settings using the repository's standard backend configuration.
## Deployment
```bash
terraform init -input=false -reconfigure -backend-config=backend.hcl
terraform fmt -check -recursive
terraform validate
terraform plan -input=false -out=tfplan
terraform apply -input=false tfplan
terraform plan -input=false
```
## Destroy
```bash
terraform destroy -input=false
```
## Expected outcome
Terraform creates two supporting rule groups and two firewall policies. The post-apply plan should report no changes.
