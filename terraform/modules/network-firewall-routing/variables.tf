##################################################################################################
# VPC Routes
##################################################################################################
# Routes are managed as standalone aws_route resources. Do not define inline route blocks on the
# same route tables because Terraform cannot safely manage inline and standalone routes together.
variable "vpc_routes" {
  description = "VPC routes keyed by stable logical identifiers."
  type = map(object({
    route_table_id              = string
    destination_cidr_block      = optional(string)
    destination_ipv6_cidr_block = optional(string)
    destination_prefix_list_id  = optional(string)
    target = object({
      carrier_gateway_id        = optional(string)
      core_network_arn          = optional(string)
      egress_only_gateway_id    = optional(string)
      gateway_id                = optional(string)
      local_gateway_id          = optional(string)
      nat_gateway_id            = optional(string)
      network_interface_id      = optional(string)
      odb_network_arn           = optional(string)
      transit_gateway_id        = optional(string)
      vpc_endpoint_id           = optional(string)
      vpc_peering_connection_id = optional(string)
    })
    timeouts = optional(object({
      create = optional(string, "5m")
      update = optional(string, "2m")
      delete = optional(string, "5m")
    }), {})
  }))
  default = {}
  validation {
    condition = alltrue([
      for route in values(var.vpc_routes) :
      can(regex("^rtb-[0-9a-f]+$", route.route_table_id))
    ])
    error_message = "Every VPC route route_table_id must use the AWS route table identifier format."
  }
  validation {
    condition = alltrue([
      for route in values(var.vpc_routes) :
      (route.destination_cidr_block != null ? 1 : 0) +
      (route.destination_ipv6_cidr_block != null ? 1 : 0) +
      (route.destination_prefix_list_id != null ? 1 : 0) == 1
    ])
    error_message = "Every VPC route must define exactly one destination: destination_cidr_block, destination_ipv6_cidr_block, or destination_prefix_list_id."
  }
  validation {
    condition = alltrue([
      for route in values(var.vpc_routes) :
      route.destination_cidr_block == null || can(cidrhost(route.destination_cidr_block, 0))
    ])
    error_message = "destination_cidr_block must be a valid IPv4 CIDR block."
  }
  validation {
    condition = alltrue([
      for route in values(var.vpc_routes) :
      route.destination_ipv6_cidr_block == null || can(cidrhost(route.destination_ipv6_cidr_block, 0))
    ])
    error_message = "destination_ipv6_cidr_block must be a valid IPv6 CIDR block."
  }
  validation {
    condition = alltrue([
      for route in values(var.vpc_routes) :
      route.destination_prefix_list_id == null || can(regex("^pl-[0-9a-f]+$", route.destination_prefix_list_id))
    ])
    error_message = "destination_prefix_list_id must use the AWS managed prefix list identifier format."
  }
  validation {
    condition = alltrue([
      for route in values(var.vpc_routes) :
      (route.target.carrier_gateway_id != null ? 1 : 0) +
      (route.target.core_network_arn != null ? 1 : 0) +
      (route.target.egress_only_gateway_id != null ? 1 : 0) +
      (route.target.gateway_id != null ? 1 : 0) +
      (route.target.local_gateway_id != null ? 1 : 0) +
      (route.target.nat_gateway_id != null ? 1 : 0) +
      (route.target.network_interface_id != null ? 1 : 0) +
      (route.target.odb_network_arn != null ? 1 : 0) +
      (route.target.transit_gateway_id != null ? 1 : 0) +
      (route.target.vpc_endpoint_id != null ? 1 : 0) +
      (route.target.vpc_peering_connection_id != null ? 1 : 0) == 1
    ])
    error_message = "Every VPC route must define exactly one route target."
  }
  validation {
    condition = alltrue([
      for route in values(var.vpc_routes) :
      !(route.destination_prefix_list_id != null && route.target.vpc_endpoint_id != null)
    ])
    error_message = "Do not combine destination_prefix_list_id with vpc_endpoint_id; use aws_vpc_endpoint_route_table_association for gateway endpoints."
  }
}
##################################################################################################
# VPC Route Table Associations
##################################################################################################
# Associations can attach a route table to a subnet or to an internet/virtual private gateway.
variable "route_table_associations" {
  description = "VPC route table associations keyed by stable logical identifiers."
  type = map(object({
    route_table_id = string
    subnet_id      = optional(string)
    gateway_id     = optional(string)
    timeouts = optional(object({
      create = optional(string, "5m")
      update = optional(string, "2m")
      delete = optional(string, "5m")
    }), {})
  }))
  default = {}
  validation {
    condition = alltrue([
      for association in values(var.route_table_associations) :
      can(regex("^rtb-[0-9a-f]+$", association.route_table_id))
    ])
    error_message = "Every route table association route_table_id must use the AWS route table identifier format."
  }
  validation {
    condition = alltrue([
      for association in values(var.route_table_associations) :
      (association.subnet_id != null ? 1 : 0) +
      (association.gateway_id != null ? 1 : 0) == 1
    ])
    error_message = "Every route table association must define exactly one of subnet_id or gateway_id."
  }
  validation {
    condition = alltrue([
      for association in values(var.route_table_associations) :
      association.subnet_id == null || can(regex("^subnet-[0-9a-f]+$", association.subnet_id))
    ])
    error_message = "subnet_id must use the AWS subnet identifier format."
  }
  validation {
    condition = alltrue([
      for association in values(var.route_table_associations) :
      association.gateway_id == null || can(regex("^(igw|vgw)-[0-9a-f]+$", association.gateway_id))
    ])
    error_message = "gateway_id must identify an internet gateway or virtual private gateway."
  }
}
##################################################################################################
# Transit Gateway Static Routes
##################################################################################################
variable "transit_gateway_routes" {
  description = "Transit Gateway static and blackhole routes keyed by stable logical identifiers."
  type = map(object({
    transit_gateway_route_table_id = string
    destination_cidr_block         = string
    transit_gateway_attachment_id  = optional(string)
    blackhole                      = optional(bool, false)
  }))
  default = {}
  validation {
    condition = alltrue([
      for route in values(var.transit_gateway_routes) :
      can(regex("^tgw-rtb-[0-9a-z]+$", route.transit_gateway_route_table_id))
    ])
    error_message = "transit_gateway_route_table_id must use the AWS Transit Gateway route table identifier format."
  }
  validation {
    condition = alltrue([
      for route in values(var.transit_gateway_routes) :
      can(cidrhost(route.destination_cidr_block, 0))
    ])
    error_message = "Transit Gateway route destinations must be valid IPv4 or IPv6 CIDR blocks."
  }
  validation {
    condition = alltrue([
      for route in values(var.transit_gateway_routes) :
      route.blackhole ? route.transit_gateway_attachment_id == null : route.transit_gateway_attachment_id != null
    ])
    error_message = "Blackhole routes must omit transit_gateway_attachment_id; non-blackhole routes must define it."
  }
  validation {
    condition = alltrue([
      for route in values(var.transit_gateway_routes) :
      route.transit_gateway_attachment_id == null ||
      can(regex("^tgw-attach-[0-9a-z]+$", route.transit_gateway_attachment_id))
    ])
    error_message = "transit_gateway_attachment_id must use the AWS Transit Gateway attachment identifier format."
  }
}
##################################################################################################
# Transit Gateway Route Table Associations
##################################################################################################
variable "transit_gateway_route_table_associations" {
  description = "Transit Gateway route table associations keyed by stable logical identifiers."
  type = map(object({
    transit_gateway_route_table_id = string
    transit_gateway_attachment_id  = string
    replace_existing_association   = optional(bool, false)
  }))
  default = {}
  validation {
    condition = alltrue([
      for association in values(var.transit_gateway_route_table_associations) :
      can(regex("^tgw-rtb-[0-9a-z]+$", association.transit_gateway_route_table_id)) &&
      can(regex("^tgw-attach-[0-9a-z]+$", association.transit_gateway_attachment_id))
    ])
    error_message = "Transit Gateway route table associations require valid route table and attachment IDs."
  }
}
##################################################################################################
# Transit Gateway Route Table Propagations
##################################################################################################
variable "transit_gateway_route_table_propagations" {
  description = "Transit Gateway route table propagations keyed by stable logical identifiers."
  type = map(object({
    transit_gateway_route_table_id = string
    transit_gateway_attachment_id  = string
  }))
  default = {}
  validation {
    condition = alltrue([
      for propagation in values(var.transit_gateway_route_table_propagations) :
      can(regex("^tgw-rtb-[0-9a-z]+$", propagation.transit_gateway_route_table_id)) &&
      can(regex("^tgw-attach-[0-9a-z]+$", propagation.transit_gateway_attachment_id))
    ])
    error_message = "Transit Gateway route table propagations require valid route table and attachment IDs."
  }
}
