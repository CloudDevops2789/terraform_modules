# Managed Microsoft AD Module Test

## Purpose

Validates `terraform/modules/managed-microsoft-ad` by deploying one AWS
Managed Microsoft AD directory into two dedicated private subnets in different
Availability Zones.

The supporting VPC is not the module under test.

## Supporting topology

The VPC uses the keyed VPC interface:

- route-table group: `directory-services`
- subnet keys: `directory-services-a`, `directory-services-b`
- Internet Gateway: disabled
- NAT Gateway: not created
- environment routes: none

The directory consumes:

```hcl
subnet_ids = module.vpc.subnet_ids_by_group["directory-services"]
```

## Local configuration

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
```

Set an approved value for `managed_ad_password` in the ignored
`terraform.tfvars` file or through `TF_VAR_managed_ad_password`.

Never commit passwords, backend configuration, state, plans, or logs.

## Initialize and validate

```bash
terraform init -input=false -reconfigure -backend-config=backend.hcl
terraform fmt -check -recursive
terraform validate
terraform plan -input=false -var-file=terraform.tfvars
```

## Expected plan

The supporting VPC creates:

- one VPC
- two private subnets
- two route tables
- two subnet-to-route-table associations

The module under test creates one AWS Managed Microsoft AD directory.

No Internet Gateway, NAT Gateway, public subnet, or default route is expected.

## Apply and destroy

AWS Managed Microsoft AD has a non-trivial hourly cost and can take a
significant amount of time to provision or delete. Apply only during an
approved deployment test and destroy immediately after validation.

```bash
terraform apply -var-file=terraform.tfvars
terraform destroy -var-file=terraform.tfvars
```
