locals {
  ##################################################################################################
  # Normalized Routing Collections
  ##################################################################################################
  vpc_routes                               = var.vpc_routes
  route_table_associations                 = var.route_table_associations
  transit_gateway_routes                   = var.transit_gateway_routes
  transit_gateway_route_table_associations = var.transit_gateway_route_table_associations
  transit_gateway_route_table_propagations = var.transit_gateway_route_table_propagations
}
