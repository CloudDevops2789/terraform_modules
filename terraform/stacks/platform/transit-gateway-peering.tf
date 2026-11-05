##################################################################################################
# External Transit Gateway Peering
##################################################################################################
#
# The IRE Transit Gateway is the accepter side of an externally initiated
# Transit Gateway peering request.
#
# The requester creates the peering attachment and provides its attachment ID.
# Platform accepts and manages the IRE side when peering is explicitly enabled.
#
# Route-table association and static routing are intentionally managed
# separately so acceptance does not implicitly establish network reachability.
##################################################################################################

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "external" {
  count = var.network_config.transit_gateway_peering.enabled ? 1 : 0

  transit_gateway_attachment_id = (
    var.network_config.transit_gateway_peering.attachment_id
  )

  tags = merge(
    local.org_tags,
    {
      Name = "${local.name_prefix}-tgw-peer"
    }
  )
}

##################################################################################################
# External Peering Route Table Association
##################################################################################################
#
# Traffic entering the IRE through the external TGW peering attachment uses
# a dedicated TGW route table. This prevents the peer from directly using
# the Inspection route table, which already knows routes to the recovery VPCs.
##################################################################################################

resource "aws_ec2_transit_gateway_route_table_association" "external_peer" {
  count = var.network_config.transit_gateway_peering.enabled ? 1 : 0

  transit_gateway_attachment_id = (
    aws_ec2_transit_gateway_peering_attachment_accepter.external[0].id
  )

  transit_gateway_route_table_id = (
    module.transit_gateway.route_table_ids["external_peer"]
  )
}