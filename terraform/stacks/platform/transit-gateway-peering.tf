##################################################################################################
# External Transit Gateway Peering
##################################################################################################
#
# IRE consumes an existing, externally managed TGW peering attachment.
# Creation, acceptance, and deletion remain outside Terraform ownership.
#
# Platform manages the IRE-side route-table association.
##################################################################################################

resource "aws_ec2_transit_gateway_route_table_association" "external_peer" {
  count = var.network_config.transit_gateway_peering.enabled ? 1 : 0

  transit_gateway_attachment_id = (
    var.network_config.transit_gateway_peering.attachment_id
  )

  transit_gateway_route_table_id = (
    module.transit_gateway.route_table_ids["external_peer"]
  )
}
