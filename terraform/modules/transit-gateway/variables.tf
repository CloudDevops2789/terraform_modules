# Module inputs. Only `name` is required (no default); everything else
# has sensible defaults so a minimal call is just name + attachments.
variable "name" {
  description = "Transit Gateway name"
  type        = string
}

# BGP Autonomous System Number for the AWS side - only matters once
# VPN/Direct Connect attachments join. 64512 is the start of the private
# ASN range and the AWS default.
variable "amazon_side_asn" {
  description = "Amazon side ASN"
  type        = number
  default     = 64512
}

variable "dns_support" {
  description = "Enable DNS support"
  type        = string
  default     = "enable"
}

variable "vpn_ecmp_support" {
  description = "Enable VPN ECMP"
  type        = string
  default     = "enable"
}

variable "auto_accept_shared_attachments" {
  description = "Auto accept shared attachments"
  type        = string
  default     = "disable"
}

variable "default_route_table_association" {
  description = "Whether new VPC attachments automatically associate with the default Transit Gateway route table."
  type        = string
  default     = "disable"

  validation {
    condition     = contains(["enable", "disable"], var.default_route_table_association)
    error_message = "Value must be either \"enable\" or \"disable\"."
  }
}

variable "default_route_table_propagation" {
  description = "Whether new VPC attachments automatically propagate routes to the default Transit Gateway route table."
  type        = string
  default     = "disable"

  validation {
    condition     = contains(["enable", "disable"], var.default_route_table_propagation)
    error_message = "Value must be either \"enable\" or \"disable\"."
  }
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

# A map(object) - the richest kind of type constraint. Each entry
# describes one VPC attachment with a fixed schema.
# optional(type, default) inside an object means the caller may omit that
# attribute and Terraform fills the default - this is how the sandbox can
# pass only vpc_id + subnet_ids while the module still reads
# each.value.dns_support safely.
variable "vpc_attachments" {
  description = "Transit Gateway VPC attachments"

  type = map(object({
    vpc_id     = string
    subnet_ids = list(string)

    # Transit Gateway route table this attachment should associate with.
    # The value must match a key defined in `var.route_tables`.
    route_table = string

    # Transit Gateway route tables this attachment should propagate into.
    # Values must match keys defined in `var.route_tables`.
    propagate_to = list(string)

    dns_support            = optional(string, "enable")
    ipv6_support           = optional(string, "disable")
    appliance_mode_support = optional(string, "disable")

    tags = optional(map(string), {})
  }))

  default = {}
}

# Transit Gateway route tables to create.
# The map key is an internal identifier while `name` becomes
# the friendly name shown in the AWS Console.
variable "route_tables" {
  description = "Transit Gateway route tables"

  type = map(object({
    name = string

    # Optional tags specific to this route table.
    tags = optional(map(string), {})
  }))

  default = {}
}
