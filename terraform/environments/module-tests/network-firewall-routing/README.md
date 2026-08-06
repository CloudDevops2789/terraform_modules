# Network Firewall Routing Module Test
## Purpose
This independent Terraform root validates `terraform/modules/network-firewall-routing`.
## Prerequisites
The repository must contain the validated:
- `terraform/modules/network-firewall-policy`
- `terraform/modules/network-firewall`
## Resources created
- One VPC and internet gateway
- One protected workload subnet
- One dedicated Network Firewall subnet
- One Transit Gateway attachment subnet
- Four VPC route tables
- One firewall policy and one Network Firewall endpoint
- One Transit Gateway and VPC attachment
- Two Transit Gateway route tables
- Four route table associations
- Four VPC routes
- One Transit Gateway route table association
- One Transit Gateway route table propagation
- One static Transit Gateway attachment route
- One Transit Gateway blackhole route
## Routing paths validated
- Workload default route to Network Firewall endpoint
- Firewall subnet default route to internet gateway
- Internet gateway ingress route to Network Firewall endpoint
- Transit Gateway attachment subnet default route to Network Firewall endpoint
## Cost warning
AWS Network Firewall and Transit Gateway resources are billable while deployed. Destroy this test immediately after lifecycle validation.
## Backend
The S3 state key is:
```text
module-tests/network-firewall-routing/terraform.tfstate
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
The firewall and Transit Gateway attachment can take several minutes to become ready.
## Expected result
The post-apply plan should report:
```text
No changes. Your infrastructure matches the configuration.
```
## Destroy
```bash
terraform destroy -input=false
```
Protection settings and automatic Transit Gateway route-table behavior are disabled so destroy can complete cleanly.
