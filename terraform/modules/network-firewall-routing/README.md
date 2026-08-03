# AWS Network Firewall Routing Module
**Status:** Enterprise module
**Terraform:** `>= 1.5.0`
**AWS provider:** `>= 6.55, < 7.0`
## Purpose
This module manages routing resources used to steer traffic through AWS Network Firewall endpoints:
```text
network-firewall-rule-group
        ↓
network-firewall-policy
        ↓
network-firewall
        ↓
network-firewall-routing
```
The module owns standalone VPC routes, VPC route table associations, Transit Gateway static routes, Transit Gateway route table associations, and Transit Gateway route table propagations.
It does not create VPCs, route tables, gateways, Transit Gateways, attachments, firewall endpoints, or firewall policies.
## Why routing is separate
Routing has a different lifecycle and ownership model from firewall resources. Separating it allows:
- Network teams to control traffic paths independently from security policy changes.
- Firewall resources to be replaced without recreating route tables.
- Existing enterprise route tables and Transit Gateway constructs to be consumed by ID.
- Centralized inspection and distributed egress architectures to use the same routing API.
## VPC route support
The module mirrors standalone `aws_route` destinations and targets.
Destinations:
- IPv4 CIDR
- IPv6 CIDR
- Managed prefix list
Targets:
- Network Firewall or other VPC endpoint
- Transit Gateway
- Internet or virtual private gateway
- NAT gateway
- Egress-only internet gateway
- Network interface
- VPC peering connection
- Carrier gateway
- Cloud WAN core network
- Local gateway
- ODB network
Each route must define exactly one destination and exactly one target.
## Network Firewall endpoint routing
Use endpoint IDs exported by `network-firewall`:
```hcl
vpc_routes = {
  workload_default_us_east_1a = {
    route_table_id         = aws_route_table.workload["us-east-1a"].id
    destination_cidr_block = "0.0.0.0/0"
    target = {
      vpc_endpoint_id = module.network_firewall.endpoint_ids_by_availability_zone["inspection"]["us-east-1a"]
    }
  }
}
```
Keep traffic zonally aligned: route each protected subnet through the firewall endpoint in the same Availability Zone.
## Internet ingress routing
Associate an edge route table with an internet gateway, then route protected subnet CIDRs to the same-AZ firewall endpoint:
```hcl
route_table_associations = {
  internet_gateway = {
    route_table_id = aws_route_table.ingress.id
    gateway_id     = aws_internet_gateway.this.id
  }
}
vpc_routes = {
  ingress_to_workload_a = {
    route_table_id         = aws_route_table.ingress.id
    destination_cidr_block = aws_subnet.workload["us-east-1a"].cidr_block
    target = {
      vpc_endpoint_id = module.network_firewall.endpoint_ids_by_availability_zone["inspection"]["us-east-1a"]
    }
  }
}
```
Bidirectional inspection requires routes on both sides of the firewall path.
## Transit Gateway routing
The module supports:
- Static routes to attachments
- Blackhole routes
- Route table associations
- Route table propagations
Example:
```hcl
transit_gateway_routes = {
  default_to_inspection = {
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
    destination_cidr_block         = "0.0.0.0/0"
    transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  }
  blocked_network = {
    transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
    destination_cidr_block         = "192.0.2.0/24"
    blackhole                      = true
  }
}
```
## Route table ownership
Do not use this module's standalone `aws_route` resources against route tables that also define inline `route` blocks. Terraform cannot safely manage the same routes through both methods and will produce conflicts or route churn.
Similarly, do not manage the same Transit Gateway association or propagation both through attachment defaults and through this module.
## Inputs
- `vpc_routes`
- `route_table_associations`
- `transit_gateway_routes`
- `transit_gateway_route_table_associations`
- `transit_gateway_route_table_propagations`
## Outputs
- `vpc_routes`
- `vpc_route_ids`
- `route_table_associations`
- `transit_gateway_routes`
- `transit_gateway_route_table_associations`
- `transit_gateway_route_table_propagations`
## Testing
The companion apply test creates:
- One VPC and internet gateway
- Protected, firewall, and Transit Gateway attachment subnets
- One Network Firewall endpoint and policy
- Three VPC route tables
- Internet gateway and subnet associations
- Bidirectional Network Firewall endpoint routes
- One Transit Gateway and VPC attachment
- Two Transit Gateway route tables
- One association, one propagation, one attachment route, and one blackhole route
AWS Network Firewall and Transit Gateway resources are billable. Destroy the test immediately after validation.
