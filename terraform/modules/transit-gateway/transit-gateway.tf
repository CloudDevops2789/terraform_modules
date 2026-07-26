# The Transit Gateway is a regional cloud router: VPCs attach to it and it
# routes between them, replacing an unscalable mesh of VPC peerings.
#
# Note the enable/disable values are STRINGS, not booleans - a quirk of the
# EC2 API that this provider mirrors.
#
# default_route_table_association/propagation default to "disable" in this
# module. That is deliberate: leaving them enabled would auto-wire every
# attachment into one shared route table, giving any-to-any reachability
# between all attached VPCs. Disabling them means an attachment can only
# reach what route-tables.tf, associations.tf and propagations.tf explicitly
# allow, which is what makes segmented (least-privilege) routing possible.
resource "aws_ec2_transit_gateway" "this" {

  description = var.name

  amazon_side_asn                 = var.amazon_side_asn
  dns_support                     = var.dns_support
  vpn_ecmp_support                = var.vpn_ecmp_support
  auto_accept_shared_attachments  = var.auto_accept_shared_attachments
  default_route_table_association = var.default_route_table_association
  default_route_table_propagation = var.default_route_table_propagation

  tags = local.tags
}
