locals {
  ##################################################################################################
  # Firewall Normalization
  ##################################################################################################
  # Per-firewall tags override common module tags while provider-level default_tags remain external.
  firewalls = {
    for key, firewall in var.firewalls : key => merge(firewall, {
      tags = merge(var.tags, firewall.tags)
    })
  }
  ##################################################################################################
  # VPC Endpoint Association Normalization
  ##################################################################################################
  vpc_endpoint_associations = {
    for key, association in var.vpc_endpoint_associations : key => merge(association, {
      tags = merge(var.tags, association.tags)
    })
  }
}
