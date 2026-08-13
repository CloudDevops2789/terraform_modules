# VPC Endpoints Module

Reusable Terraform module for creating AWS Interface and Gateway VPC
endpoints.

The module is intentionally service-agnostic and topology-agnostic. The
calling environment determines which AWS services are required, where
endpoints are placed, which route tables participate, and which security
groups control access.

## Purpose

Use this module to provide private access from a VPC to supported AWS services
without embedding application-specific or recovery-specific assumptions in the
module itself.

## Capabilities

- Multiple Interface endpoints
- Multiple Gateway endpoints
- Multi-AZ Interface endpoint placement
- Caller-controlled endpoint security groups
- Optional private DNS for Interface endpoints
- Optional endpoint policies
- Gateway endpoint route-table associations
- Common and endpoint-specific tags
- Stable logical addressing through `for_each`

## Architecture

~~~mermaid
flowchart TD
    VPC[VPC] --> Interface[Interface Endpoint]
    Interface --> ENIA[Endpoint ENI - AZ A]
    Interface --> ENIB[Endpoint ENI - AZ B]
    Interface --> SG[Caller-managed Security Group]

    VPC --> Gateway[Gateway Endpoint]
    Gateway --> RTA[Route Table A]
    Gateway --> RTB[Route Table B]
~~~

## Security Group Ownership

This module intentionally does not create security groups.

Interface endpoint security groups are supplied by the calling environment:

    security_group_ids = [
      module.security_group.security_group_ids["vpc-endpoints"]
    ]

This preserves separation between:

    Endpoint lifecycle
          and
    Network security policy

It also allows existing organization-approved security groups to be consumed.

## Interface Endpoint Inputs

Each Interface endpoint supports:

| Attribute | Required | Description |
|---|---:|---|
| `name` | No | Optional Name tag. |
| `service_name` | Yes | Full AWS endpoint service name. |
| `subnet_ids` | Yes | One or more endpoint subnet IDs. |
| `security_group_ids` | Yes | One or more security-group IDs. |
| `private_dns_enabled` | No | Enables private service DNS. Defaults to true. |
| `policy` | No | Endpoint policy as valid JSON. |
| `tags` | No | Endpoint-specific tags. |

## Interface Endpoint Example

    module "vpc_endpoints" {
      source = "../../modules/vpc-endpoints"

      vpc_id = module.application_vpc.vpc_id

      interface_endpoints = {
        service_api = {
          name         = "org-service-api"
          service_name = "com.amazonaws.us-east-1.example"

          subnet_ids = [
            module.application_vpc.subnet_ids["endpoints-a"],
            module.application_vpc.subnet_ids["endpoints-b"]
          ]

          security_group_ids = [
            module.security_group.security_group_ids["vpc-endpoints"]
          ]

          private_dns_enabled = true
        }
      }

      tags = {
        org_environment = "recovery"
        org_managed_by  = "Terraform"
      }
    }

The example service name is illustrative. The caller must provide a valid
service name for the target AWS Region and service.

## Systems Manager Example

Systems Manager is one example consumer of this generic module.

    module "management_endpoints" {
      source = "../../modules/vpc-endpoints"

      vpc_id = module.application_vpc.vpc_id

      interface_endpoints = {
        ssm = {
          name = "org-ssm"

          service_name =
            "com.amazonaws.${var.aws_region}.ssm"

          subnet_ids = [
            module.application_vpc.subnet_ids["endpoints-a"],
            module.application_vpc.subnet_ids["endpoints-b"]
          ]

          security_group_ids = [
            module.security_group.security_group_ids["vpc-endpoints"]
          ]

          private_dns_enabled = true
        }

        ssmmessages = {
          name = "org-ssmmessages"

          service_name =
            "com.amazonaws.${var.aws_region}.ssmmessages"

          subnet_ids = [
            module.application_vpc.subnet_ids["endpoints-a"],
            module.application_vpc.subnet_ids["endpoints-b"]
          ]

          security_group_ids = [
            module.security_group.security_group_ids["vpc-endpoints"]
          ]

          private_dns_enabled = true
        }
      }
    }

The calling environment is responsible for determining the exact service
endpoints required for its Region, operating model, workloads, and approved
management architecture.

The VPC endpoint module itself does not hard-code Systems Manager.

## Gateway Endpoint Inputs

Each Gateway endpoint supports:

| Attribute | Required | Description |
|---|---:|---|
| `name` | No | Optional Name tag. |
| `service_name` | Yes | Full AWS gateway endpoint service name. |
| `route_table_ids` | Yes | Associated route-table IDs. |
| `policy` | No | Endpoint policy as valid JSON. |
| `tags` | No | Endpoint-specific tags. |

## S3 Gateway Endpoint Example

    module "vpc_endpoints" {
      source = "../../modules/vpc-endpoints"

      vpc_id = module.application_vpc.vpc_id

      gateway_endpoints = {
        s3 = {
          name =
            "org-s3"

          service_name =
            "com.amazonaws.${var.aws_region}.s3"

          route_table_ids = [
            module.application_vpc.route_table_ids["application-a"],
            module.application_vpc.route_table_ids["application-b"]
          ]
        }
      }
    }

## Endpoint Policy Example

Both endpoint types support an optional endpoint policy.

    policy = jsonencode({
      Version = "2012-10-17"

      Statement = [
        {
          Effect    = "Allow"
          Principal = "*"
          Action    = ["s3:GetObject"]
          Resource  = ["arn:aws:s3:::example-bucket/*"]
        }
      ]
    })

Endpoint policies should follow the approved least-privilege model for the
calling environment.

## Outputs

Interface endpoint outputs include:

- `interface_endpoint_ids`
- `interface_endpoint_arns`
- `interface_endpoint_dns_entries`
- `interface_endpoint_network_interface_ids`

Gateway endpoint outputs include:

- `gateway_endpoint_ids`
- `gateway_endpoint_arns`
- `gateway_endpoint_prefix_list_ids`

Outputs are keyed by the logical endpoint key supplied by the caller.

## Private DNS

`private_dns_enabled` defaults to true for Interface endpoints.

The caller must review DNS behavior before enabling private DNS, particularly
where hybrid DNS, Route 53 Resolver, split-horizon DNS, centralized endpoint
patterns, or cross-VPC name resolution are involved.

## Security Considerations

Endpoint connectivity does not by itself authorize an AWS API request.

Effective authorization can involve:

- IAM identity policies
- endpoint policies
- service resource policies
- security groups
- DNS
- network routing

Restrict Interface endpoint security groups to approved source networks and
required ports.

Use endpoint policies where service-level restriction is required.

## Lifecycle

VPC endpoints commonly belong to the persistent platform layer rather than to
individual temporary workloads.

For example:

~~~mermaid
flowchart LR
    Persistent[Persistent Platform] --> VPC[VPC]
    Persistent --> Subnets[Subnets]
    Persistent --> Routing[Routing]
    Persistent --> Security[Endpoint Security Controls]
    Persistent --> Endpoints[Interface and Gateway Endpoints]

    Temporary[Temporary Workloads] --> EC2[EC2]
    Temporary --> Validation[Validation Compute]
    Temporary --> Recovery[Recovered Application Resources]
~~~

The calling environment determines the lifecycle. The generic module imposes
no persistent or ephemeral behavior.

## Centralized vs Distributed Endpoints

The module supports either architecture.

Distributed model:

~~~mermaid
flowchart LR
    A[VPC A] --> EA[Local Endpoint]
    B[VPC B] --> EB[Local Endpoint]
    C[VPC C] --> EC[Local Endpoint]
~~~

Centralized model:

~~~mermaid
flowchart LR
    A[VPC A] --> Shared[Shared Endpoint Architecture]
    B[VPC B] --> Shared
    C[VPC C] --> Shared
~~~

Routing, DNS, blast-radius, cost, inspection, isolation, and recovery
requirements should determine which pattern is selected.

## Validation

A reusable module test is located at:

    terraform/environments/module-tests/vpc-endpoints

The test demonstrates:

- Interface endpoints
- multiple endpoint subnets
- caller-provided endpoint security groups
- private DNS
- Gateway endpoints
- multiple route tables
- reusable tagging

The module remains independent of the example AWS services.
