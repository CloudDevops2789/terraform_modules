# Network Firewall Logging Module Test
## Purpose
This independent Terraform root validates `terraform/modules/network-firewall-logging`.
## Prerequisites
The repository must contain the validated:
- `terraform/modules/network-firewall-policy`
- `terraform/modules/network-firewall`
## Resources created
- One VPC
- One dedicated Network Firewall subnet
- One minimal firewall policy
- One Network Firewall endpoint
- Two CloudWatch log groups
- One Network Firewall logging configuration with ALERT and FLOW logs
- Detailed firewall monitoring dashboard enabled
## Cost warning
AWS Network Firewall is billable while deployed. CloudWatch Logs can also incur ingestion and storage charges. Destroy this test immediately after lifecycle validation.
## Backend
The S3 state key is:
```text
module-tests/network-firewall-logging/terraform.tfstate
```
## Deployment
```bash
terraform init -input=false -reconfigure -backend-config=backend.hcl
terraform fmt -check -recursive
terraform validate
terraform plan -input=false -out=tfplan
terraform apply -input=false tfplan
terraform plan -input=false
```
The Network Firewall can take several minutes to become ready before logging is configured.
## Expected result
The apply creates the supporting network and firewall, then attaches ALERT and FLOW CloudWatch Logs destinations. The post-apply plan should report no changes.
## Destroy
```bash
terraform destroy -input=false
```
Protection settings are disabled so destroy can complete without an intermediate firewall update.
## Scope
The apply test validates CloudWatch Logs delivery and monitoring-dashboard configuration. S3, Firehose, and TLS inputs are covered by the reusable module's typed interface and validations but are not deployed here to avoid additional infrastructure and TLS inspection dependencies.
