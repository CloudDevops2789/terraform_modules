# AWS Network Firewall Module
**Status:** Enterprise module
**Terraform:** `>= 1.5.0`
**AWS provider:** `>= 6.51, < 7.0`
## Purpose
This module creates AWS Network Firewall firewalls and optional additional VPC endpoint associations. It is the final resource layer of the repository's core Network Firewall suite:
```text
network-firewall-rule-group
        ↓
network-firewall-policy
        ↓
network-firewall
```
The module accepts VPC, subnet, Transit Gateway, firewall policy, and KMS identifiers from the consuming root. It does not create VPCs, route tables, Transit Gateways, firewall policies, KMS keys, log destinations, or cross-account acceptance resources.
## Supported deployment models
### VPC-attached firewall
A VPC-attached firewall requires:
- `vpc_id`
- One or more `subnet_mappings`
- One dedicated Network Firewall subnet per Availability Zone
The module exports endpoint IDs by Availability Zone and subnet ID for route-table integration.
### Transit Gateway-attached firewall
A Transit Gateway-attached firewall requires:
- `transit_gateway_id`
- One or more `availability_zone_mappings`
The Transit Gateway ID is immutable. Cross-account deployments may require `aws_networkfirewall_firewall_transit_gateway_attachment_accepter` in the Transit Gateway owner's account.
### Additional VPC endpoint associations
Optional `vpc_endpoint_associations` create extra firewall endpoints for a VPC-attached firewall. An association may reference:
- A firewall created by this module through `firewall_key`
- An external or shared firewall through `firewall_arn`
AWS allows an association only in an Availability Zone where the primary firewall already has an endpoint. Transit Gateway-attached firewalls do not support VPC endpoint associations.
## Firewall policy composition
The module intentionally accepts `firewall_policy_arn` rather than a policy name or an internal policy key. The caller resolves the ARN:
```hcl
firewall_policy_arn = module.network_firewall_policy.firewall_policy_arns["inspection"]
```
This same input also accepts a policy ARN from remote state, AWS RAM, another repository, or another account. Keeping ARN resolution in the root module preserves clean module boundaries and avoids hidden data-source lookups.
## VPC-attached example
```hcl
module "network_firewall" {
  source = "../../modules/network-firewall"
  firewalls = {
    inspection = {
      name                = "ire-inspection-firewall"
      description         = "Centralized enterprise inspection firewall."
      firewall_policy_arn = module.network_firewall_policy.firewall_policy_arns["inspection"]
      vpc_id              = module.inspection_vpc.vpc_id
      subnet_mappings = {
        us_east_1a = {
          subnet_id       = module.inspection_vpc.firewall_subnet_ids_by_az["us-east-1a"]
          ip_address_type = "IPV4"
        }
        us_east_1b = {
          subnet_id       = module.inspection_vpc.firewall_subnet_ids_by_az["us-east-1b"]
          ip_address_type = "IPV4"
        }
      }
      enabled_analysis_types            = ["HTTP_HOST", "TLS_SNI"]
      delete_protection                  = true
      firewall_policy_change_protection = true
      subnet_change_protection          = true
    }
  }
  tags = {
    org_project_name = "replace-with-approved-project-name"
    org_managed_by = "Terraform"
  }
}
```
## Transit Gateway-attached example
```hcl
module "network_firewall" {
  source = "../../modules/network-firewall"
  firewalls = {
    centralized = {
      name                = "ire-centralized-tgw-firewall"
      firewall_policy_arn = module.network_firewall_policy.firewall_policy_arns["inspection"]
      transit_gateway_id  = module.transit_gateway.transit_gateway_id
      availability_zone_mappings = {
        use1_az1 = {
          availability_zone_id = "use1-az1"
        }
        use1_az2 = {
          availability_zone_id = "use1-az2"
        }
      }
      availability_zone_change_protection = true
      delete_protection                   = true
      firewall_policy_change_protection   = true
    }
  }
}
```
## Additional endpoint example
```hcl
module "network_firewall" {
  source = "../../modules/network-firewall"
  firewalls = {
    inspection = {
      name                = "ire-inspection-firewall"
      firewall_policy_arn = module.network_firewall_policy.firewall_policy_arns["inspection"]
      vpc_id              = module.inspection_vpc.vpc_id
      subnet_mappings = {
        primary_a = {
          subnet_id = module.inspection_vpc.firewall_subnet_ids_by_az["us-east-1a"]
        }
      }
    }
  }
  vpc_endpoint_associations = {
    workload_a = {
      firewall_key = "inspection"
      vpc_id       = module.workload_vpc.vpc_id
      subnet_mapping = {
        subnet_id = module.workload_vpc.firewall_endpoint_subnet_ids_by_az["us-east-1a"]
      }
    }
  }
}
```
## Route-table integration
Use the endpoint outputs rather than attempting to discover Network Firewall endpoints through EC2 filters:
```hcl
network_firewall_endpoint_id = module.network_firewall.endpoint_ids_by_availability_zone["inspection"]["us-east-1a"]
```
Route each Availability Zone through the firewall endpoint in the same Availability Zone to preserve zonal isolation and avoid unnecessary cross-AZ data processing.
## Protection settings
The module mirrors provider defaults and leaves protection settings disabled unless explicitly enabled. Production deployments should normally evaluate:
- `delete_protection = true`
- `firewall_policy_change_protection = true`
- `subnet_change_protection = true` for VPC-attached firewalls
- `availability_zone_change_protection = true` for Transit Gateway-attached firewalls
Disable the relevant protection before intentionally changing or destroying a protected firewall.
## Traffic analysis
`enabled_analysis_types` supports:
- `TLS_SNI`
- `HTTP_HOST`
Enabling analysis collects traffic-analysis metrics; it does not automatically create analysis reports.
## Encryption
Omit `encryption_configuration` to use AWS-owned encryption. For a customer-managed key:
```hcl
encryption_configuration = {
  type   = "CUSTOMER_KMS"
  key_id = module.network_firewall_kms.key_arn
}
```
The key policy must permit AWS Network Firewall to use the key.
## Outputs
- `firewalls`
- `firewall_arns`
- `endpoint_ids_by_availability_zone`
- `endpoint_ids_by_subnet_id`
- `vpc_endpoint_associations`
- `vpc_endpoint_association_arns`
## Module boundaries
This module deliberately does not manage:
- Rule groups
- Firewall policies
- Logging configurations and destinations
- VPC route tables
- Transit Gateways
- Cross-account Transit Gateway attachment acceptance
- AWS RAM resource shares
- KMS keys
Those concerns have different ownership, lifecycle, and provider-alias requirements.
## Testing
The companion module test creates:
- A two-AZ VPC
- Two dedicated firewall subnets
- A minimal firewall policy through `network-firewall-policy`
- One VPC-attached Network Firewall
- Routing-ready endpoint outputs
AWS Network Firewall is billable while deployed. Destroy the test immediately after validation.

## Repository integration status

The module is integrated in `terraform/environments/sandbox` as one two-AZ
firewall in the dedicated centralized Inspection VPC. The environment selects
same-AZ endpoint IDs for Transit Gateway traffic. The module itself remains
topology-neutral and does not create routes.
