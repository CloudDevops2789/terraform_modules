##################################################################################################
# Module Under Test: Network Firewall Routing
##################################################################################################
module "network_firewall_routing" {
  source = "../../../modules/network-firewall-routing"
  route_table_associations = {
    workload = {
      route_table_id = aws_route_table.workload.id
      subnet_id      = aws_subnet.workload.id
    }
    firewall = {
      route_table_id = aws_route_table.firewall.id
      subnet_id      = aws_subnet.firewall.id
    }
    transit = {
      route_table_id = aws_route_table.transit.id
      subnet_id      = aws_subnet.transit.id
    }
    internet_gateway = {
      route_table_id = aws_route_table.ingress.id
      gateway_id     = aws_internet_gateway.this.id
    }
  }
  vpc_routes = {
    workload_default_to_firewall = {
      route_table_id         = aws_route_table.workload.id
      destination_cidr_block = "0.0.0.0/0"
      target = {
        vpc_endpoint_id = module.network_firewall.endpoint_ids_by_availability_zone["inspection"][local.availability_zone]
      }
    }
    firewall_default_to_internet = {
      route_table_id         = aws_route_table.firewall.id
      destination_cidr_block = "0.0.0.0/0"
      target = {
        gateway_id = aws_internet_gateway.this.id
      }
    }
    ingress_to_workload = {
      route_table_id         = aws_route_table.ingress.id
      destination_cidr_block = aws_subnet.workload.cidr_block
      target = {
        vpc_endpoint_id = module.network_firewall.endpoint_ids_by_availability_zone["inspection"][local.availability_zone]
      }
    }
    transit_default_to_firewall = {
      route_table_id         = aws_route_table.transit.id
      destination_cidr_block = "0.0.0.0/0"
      target = {
        vpc_endpoint_id = module.network_firewall.endpoint_ids_by_availability_zone["inspection"][local.availability_zone]
      }
    }
  }
  transit_gateway_route_table_associations = {
    vpc_attachment = {
      transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.association.id
      transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
    }
  }
  transit_gateway_route_table_propagations = {
    vpc_attachment = {
      transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.propagation.id
      transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
    }
  }
  transit_gateway_routes = {
    vpc_static = {
      transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.association.id
      destination_cidr_block         = var.vpc_cidr
      transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
    }
    documentation_blackhole = {
      transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.association.id
      destination_cidr_block         = "192.0.2.0/24"
      blackhole                      = true
    }
  }
}
