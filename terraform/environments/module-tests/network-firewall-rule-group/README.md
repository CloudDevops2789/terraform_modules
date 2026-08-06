# Network Firewall Rule Group Module Test
## Purpose
This independent Terraform root validates `terraform/modules/network-firewall-rule-group`.
## Module under test
The module creates collections of stateful and stateless AWS Network Firewall rule groups.
## Supporting infrastructure
None. Network Firewall rule groups are regional control-plane resources and do not require a VPC, subnets, routes, firewall policy, or firewall.
## Coverage
The test creates:
- One top-level Suricata flat-format stateful rule group
- One generated domain denylist
- One structured stateful 5-tuple rule group with IP and port variables
- One stateless rule group with address, port, protocol, TCP flag, and custom metric action configuration
## Backend
The S3 state key is fixed at:
```text
module-tests/network-firewall-rule-group/terraform.tfstate
```
Supply the shared bucket, Region, encryption, and locking settings using the repository's normal backend configuration.
## Deployment
```bash
terraform init -input=false -reconfigure -backend-config=backend.hcl
terraform fmt -check -recursive
terraform validate
terraform plan -input=false
terraform apply -input=false
```
## Destroy
```bash
terraform destroy -input=false
```
## Expected outcome
Terraform creates four independent rule groups and returns their ARNs, IDs, names, types, and update tokens.
## Notes
This environment validates only the rule-group module. Firewall policies, firewalls, logging, routing, VPCs, and Transit Gateway inspection paths are intentionally outside its scope.
