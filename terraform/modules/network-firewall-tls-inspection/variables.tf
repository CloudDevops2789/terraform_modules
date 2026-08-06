##################################################################################################
# Common Tags
##################################################################################################
variable "tags" {
  description = "Tags applied to every Network Firewall TLS inspection configuration created by this module."
  type        = map(string)
  default     = {}
}
##################################################################################################
# TLS Inspection Configurations
##################################################################################################
# Each logical map entry creates one AWS Network Firewall TLS inspection configuration. A server
# certificate configuration can support inbound inspection, outbound inspection, or both.
variable "tls_inspection_configurations" {
  description = "AWS Network Firewall TLS inspection configurations keyed by stable logical identifiers."
  type = map(object({
    name        = string
    description = optional(string)
    encryption_configuration = optional(object({
      type   = string
      key_id = optional(string)
    }))
    server_certificate_configurations = list(object({
      certificate_authority_arn = optional(string)
      check_certificate_revocation_status = optional(object({
        revoked_status_action = optional(string)
        unknown_status_action = optional(string)
      }))
      scopes = list(object({
        protocols = optional(set(number), [6])
        destinations = optional(list(object({
          address_definition = string
        })), [])
        destination_ports = optional(list(object({
          from_port = number
          to_port   = optional(number)
        })), [])
        sources = optional(list(object({
          address_definition = string
        })), [])
        source_ports = optional(list(object({
          from_port = number
          to_port   = optional(number)
        })), [])
      }))
      server_certificates = optional(list(object({
        resource_arn = string
      })), [])
    }))
    timeouts = optional(object({
      create = optional(string, "30m")
      update = optional(string, "30m")
      delete = optional(string, "30m")
    }), {})
    tags = optional(map(string), {})
  }))
  default = {}
  validation {
    condition = alltrue([
      for configuration in values(var.tls_inspection_configurations) :
      length(configuration.name) >= 1 &&
      length(configuration.name) <= 128 &&
      can(regex("^[A-Za-z0-9-]+$", configuration.name))
    ])
    error_message = "Every TLS inspection configuration name must contain 1-128 alphanumeric or hyphen characters."
  }
  validation {
    condition = alltrue([
      for configuration in values(var.tls_inspection_configurations) :
      configuration.description == null || length(configuration.description) <= 512
    ])
    error_message = "TLS inspection configuration descriptions must contain no more than 512 characters."
  }
  validation {
    condition = alltrue([
      for configuration in values(var.tls_inspection_configurations) :
      length(configuration.server_certificate_configurations) >= 1
    ])
    error_message = "Every TLS inspection configuration must define at least one server_certificate_configuration."
  }
  validation {
    condition = alltrue(flatten([
      for configuration in values(var.tls_inspection_configurations) : [
        for certificate_configuration in configuration.server_certificate_configurations :
        certificate_configuration.certificate_authority_arn != null ||
        length(certificate_configuration.server_certificates) >= 1
      ]
    ]))
    error_message = "Every server certificate configuration must define outbound certificate_authority_arn, one or more inbound server_certificates, or both."
  }
  validation {
    condition = alltrue(flatten([
      for configuration in values(var.tls_inspection_configurations) : [
        for certificate_configuration in configuration.server_certificate_configurations :
        certificate_configuration.certificate_authority_arn == null ||
        can(regex("^arn:[^:]+:acm:[^:]+:[0-9]{12}:certificate/.+$", certificate_configuration.certificate_authority_arn))
      ]
    ]))
    error_message = "certificate_authority_arn must be a valid ACM certificate ARN."
  }
  validation {
    condition = alltrue(flatten([
      for configuration in values(var.tls_inspection_configurations) : [
        for certificate_configuration in configuration.server_certificate_configurations :
        alltrue([
          for certificate in certificate_configuration.server_certificates :
          can(regex("^arn:[^:]+:acm:[^:]+:[0-9]{12}:certificate/.+$", certificate.resource_arn))
        ])
      ]
    ]))
    error_message = "Every inbound server certificate resource_arn must be a valid ACM certificate ARN."
  }
  validation {
    condition = alltrue(flatten([
      for configuration in values(var.tls_inspection_configurations) : [
        for certificate_configuration in configuration.server_certificate_configurations :
        certificate_configuration.check_certificate_revocation_status == null ||
        certificate_configuration.certificate_authority_arn != null
      ]
    ]))
    error_message = "Certificate revocation checking requires certificate_authority_arn for outbound inspection."
  }
  validation {
    condition = alltrue(flatten([
      for configuration in values(var.tls_inspection_configurations) : [
        for certificate_configuration in configuration.server_certificate_configurations :
        certificate_configuration.check_certificate_revocation_status == null ||
        certificate_configuration.check_certificate_revocation_status.revoked_status_action == null ||
        contains(
          ["PASS", "DROP", "REJECT"],
          certificate_configuration.check_certificate_revocation_status.revoked_status_action
        )
      ]
    ]))
    error_message = "revoked_status_action must be PASS, DROP, or REJECT."
  }
  validation {
    condition = alltrue(flatten([
      for configuration in values(var.tls_inspection_configurations) : [
        for certificate_configuration in configuration.server_certificate_configurations :
        certificate_configuration.check_certificate_revocation_status == null ||
        certificate_configuration.check_certificate_revocation_status.unknown_status_action == null ||
        contains(
          ["PASS", "DROP", "REJECT"],
          certificate_configuration.check_certificate_revocation_status.unknown_status_action
        )
      ]
    ]))
    error_message = "unknown_status_action must be PASS, DROP, or REJECT."
  }
  validation {
    condition = alltrue(flatten([
      for configuration in values(var.tls_inspection_configurations) : [
        for certificate_configuration in configuration.server_certificate_configurations :
        length(certificate_configuration.scopes) >= 1
      ]
    ]))
    error_message = "Every server certificate configuration must define at least one scope."
  }
  validation {
    condition = alltrue(flatten([
      for configuration in values(var.tls_inspection_configurations) : [
        for certificate_configuration in configuration.server_certificate_configurations : [
          for scope in certificate_configuration.scopes :
          length(scope.protocols) >= 1 &&
          length(setsubtract(scope.protocols, toset([6]))) == 0
        ]
      ]
    ]))
    error_message = "TLS inspection scopes support only TCP protocol number 6."
  }
  validation {
    condition = alltrue(flatten([
      for configuration in values(var.tls_inspection_configurations) : [
        for certificate_configuration in configuration.server_certificate_configurations : [
          for scope in certificate_configuration.scopes :
          alltrue([
            for address in concat(scope.sources, scope.destinations) :
            can(cidrhost(address.address_definition, 0)) &&
            can(regex("^[0-9.]+/[0-9]+$", address.address_definition))
          ])
        ]
      ]
    ]))
    error_message = "TLS inspection source and destination addresses must be valid IPv4 CIDR blocks."
  }
  validation {
    condition = alltrue(flatten([
      for configuration in values(var.tls_inspection_configurations) : [
        for certificate_configuration in configuration.server_certificate_configurations : [
          for scope in certificate_configuration.scopes :
          alltrue([
            for port in concat(scope.source_ports, scope.destination_ports) :
            port.from_port >= 0 &&
            port.from_port <= 65535 &&
            coalesce(port.to_port, port.from_port) >= port.from_port &&
            coalesce(port.to_port, port.from_port) <= 65535
          ])
        ]
      ]
    ]))
    error_message = "TLS inspection source and destination ports must use valid 0-65535 ranges."
  }
  validation {
    condition = alltrue([
      for configuration in values(var.tls_inspection_configurations) :
      configuration.encryption_configuration == null ? true :
      contains(
        ["AWS_OWNED_KMS_KEY", "CUSTOMER_KMS"],
        configuration.encryption_configuration.type
      )
    ])
    error_message = "Encryption type must be AWS_OWNED_KMS_KEY or CUSTOMER_KMS."
  }
  validation {
    condition = alltrue([
      for configuration in values(var.tls_inspection_configurations) :
      configuration.encryption_configuration == null ? true : (
        configuration.encryption_configuration.type != "CUSTOMER_KMS" ||
        try(configuration.encryption_configuration.key_id, null) != null
      )
    ])
    error_message = "CUSTOMER_KMS encryption requires key_id."
  }
}
