# Module INPUTS. Variables without a `default` (like this one) are
# required - Terraform errors if the caller omits them. Variables with a
# default are optional. `type` constraints catch wrong-shaped input at
# plan time instead of at AWS API time.
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zone_count" {
  description = "Number of Availability Zones to use"

  type    = number
  default = 2

  # VALIDATION BLOCK: a custom plan-time rule. `condition` must evaluate to
  # true or the plan fails with error_message. Cheap insurance for
  # assumptions the type system can't express (here: minimum HA of 2 AZs).
  validation {
    condition     = var.availability_zone_count >= 2
    error_message = "At least two Availability Zones are recommended."
  }
}

# Maps of name -> CIDR, e.g. { public-a = "10.0.1.0/24" }. Defaulting to
# {} makes the whole public tier optional: an empty map means for_each
# creates nothing and the conditional IGW logic switches off.
variable "public_subnets" {
  description = "Map of public subnet CIDRs"

  type = map(string)

  default = {}
}

# No default here plus a validation requiring at least one entry: every
# VPC in this design must have a private tier.
variable "private_subnets" {
  description = "Map of private subnet CIDRs"

  type = map(string)

  validation {
    condition     = length(var.private_subnets) > 0
    error_message = "At least one private subnet is required."
  }
}

variable "enable_dns_support" {
  type    = bool
  default = true
}

variable "enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}

# Optional Transit Gateway routes to install in the private route table.
# The module remains reusable by accepting a list of routes instead of
# hardcoding knowledge of specific VPCs or network topologies.
variable "public_transit_gateway_routes" {
  description = "Routes to add to the public route table via the Transit Gateway."

  type = list(object({
    destination_cidr_block = string
    transit_gateway_id     = string
  }))

  default = []
}

variable "private_transit_gateway_routes" {
  description = "Routes to add to the private route table via the Transit Gateway."

  type = list(object({
    destination_cidr_block = string
    transit_gateway_id     = string
  }))

  default = []
}