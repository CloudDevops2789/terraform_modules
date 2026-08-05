##################################################################################################
# Module Under Test: transit-gateway
##################################################################################################
# terraform/modules/transit-gateway is the module this environment exists
# to validate: the gateway, one Transit Gateway Route Table, one VPC
# attachment, the association, and one propagation.
module "transit_gateway" {

  source = "../../../modules/transit-gateway"

  name = local.transit_gateway.name

  default_route_table_association = local.transit_gateway.default_route_table_association
  default_route_table_propagation = local.transit_gateway.default_route_table_propagation

  route_tables = local.transit_gateway.route_tables

  vpc_attachments = {

    test = {

      vpc_id     = module.vpc.vpc_id
      subnet_ids = module.vpc.private_subnet_ids

      # Associates this attachment with the "main" route table and
      # propagates its CIDR back into the same table - the minimum wiring
      # needed to prove association/propagation both work, without
      # modeling any real multi-VPC routing topology.
      route_table = "main"

      propagate_to = [
        "main"
      ]
    }
  }

  tags = local.org_tags
}
