# Network Firewall Module Test
## Purpose
This independent Terraform root validates `terraform/modules/network-firewall`.
## Prerequisite
The repository must contain the validated `terraform/modules/network-firewall-policy` module.
## Resources created
- One VPC
- Two dedicated Network Firewall subnets in separate Availability Zones
- One minimal Network Firewall policy
- One VPC-attached AWS Network Firewall with two endpoints
## Cost warning
AWS Network Firewall charges for each deployed firewall endpoint and for processed traffic. This test creates two endpoints. Destroy it immediately after completing lifecycle validation.
## Backend
The S3 state key is:
```text
module-tests/network-firewall/terraform.tfstate
```
Supply shared backend settings using the repository's standard backend configuration.
## Deployment
```bash
terraform init -reconfigure
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform plan
```
The firewall can take several minutes to become ready.
## Expected post-apply result
The second plan should report:
```text
No changes. Your infrastructure matches the configuration.
```
The outputs should contain one Network Firewall endpoint ID for each selected Availability Zone.
## Destroy
```bash
terraform destroy
```
Protection settings are disabled in this test so destroy can complete without an intermediate update.
## Scope
The test validates firewall creation, policy composition, multi-AZ subnet mappings, traffic-analysis settings, status outputs, and endpoint discovery. It intentionally does not route traffic through the firewall or test Transit Gateway and cross-account architectures.
