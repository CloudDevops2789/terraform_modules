##################################################################################################
# Client VPN and Federation Variables
##################################################################################################

variable "client_vpn_enabled" {
  description = "Whether this environment creates AWS Client VPN. Keep false during initial bootstrap when enterprise PKI or identity prerequisites are not yet available."
  type        = bool
  default     = false
  nullable    = false
}

variable "authentication_type" {
  description = "Client VPN authentication method. Supported values are certificate and federated."
  type        = string
  default     = "federated"

  validation {
    condition = contains([
      "certificate",
      "federated",
    ], var.authentication_type)

    error_message = "authentication_type must be either certificate or federated."
  }
}

variable "server_certificate_arn" {
  description = "Existing ACM server certificate ARN. Required only when Client VPN is enabled."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      !var.client_vpn_enabled ||
      (
        var.server_certificate_arn != null &&
        length(trimspace(var.server_certificate_arn)) > 0
      )
    )

    error_message = "server_certificate_arn must be supplied when client_vpn_enabled is true."
  }
}

variable "root_certificate_chain_arn" {
  description = "Existing ACM root CA certificate ARN. Required only when enabled Client VPN uses certificate authentication."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      !var.client_vpn_enabled ||
      var.authentication_type != "certificate" ||
      (
        var.root_certificate_chain_arn != null &&
        length(trimspace(var.root_certificate_chain_arn)) > 0
      )
    )

    error_message = "root_certificate_chain_arn must be supplied when enabled Client VPN uses certificate authentication."
  }
}

variable "saml_provider_arn" {
  description = "Existing IAM SAML identity provider ARN used for federated Client VPN."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      !var.client_vpn_enabled ||
      var.authentication_type != "federated" ||
      var.manage_saml_provider ||
      (
        var.saml_provider_arn != null &&
        length(trimspace(var.saml_provider_arn)) > 0
      )
    )

    error_message = "saml_provider_arn must be supplied when enabled federated Client VPN uses an externally managed SAML provider."
  }
}

variable "manage_saml_provider" {
  description = "Whether Terraform manages the IAM SAML identity provider lifecycle for Client VPN."
  type        = bool
  default     = false
  nullable    = false
}

variable "saml_provider_name" {
  description = "Optional name override for a Terraform-managed IAM SAML provider."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.saml_provider_name == null ? true : (
      length(trimspace(var.saml_provider_name)) >= 1 &&
      length(trimspace(var.saml_provider_name)) <= 128 &&
      can(regex("^[A-Za-z0-9._-]+$", var.saml_provider_name))
    )

    error_message = "saml_provider_name must contain 1 to 128 characters using only letters, numbers, '.', '_', or '-'."
  }
}

variable "saml_metadata_document" {
  description = "Approved SAML 2.0 metadata XML used only when Terraform manages the IAM SAML provider."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.saml_metadata_document == null ? true : (
      length(var.saml_metadata_document) >= 1000 &&
      length(var.saml_metadata_document) <= 10000000
    )

    error_message = "saml_metadata_document must contain between 1,000 and 10,000,000 characters when provided."
  }

  validation {
    condition = (
      !var.client_vpn_enabled ||
      var.authentication_type != "federated" ||
      !var.manage_saml_provider ||
      var.saml_metadata_document != null
    )

    error_message = "saml_metadata_document is required when Terraform manages the SAML provider for an enabled federated Client VPN."
  }
}

variable "client_vpn_security_group_rule_names" {
  description = "Security-group rule names that are active only when Client VPN is enabled."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for rule_name in var.client_vpn_security_group_rule_names :
      contains(
        [for rule in var.security_group_rules : rule.name],
        rule_name
      )
    ])

    error_message = "Every client_vpn_security_group_rule_names entry must reference an existing security_group_rules name."
  }
}

variable "client_vpn_dns_configuration" {
  description = "DNS servers pushed to Client VPN users. vpc_resolver derives the associated VPC's private AmazonProvidedDNS address."

  type = object({
    mode               = optional(string, "none")
    custom_dns_servers = optional(list(string), [])
  })

  default  = {}
  nullable = false

  validation {
    condition = contains(
      ["none", "vpc_resolver", "custom"],
      var.client_vpn_dns_configuration.mode
    )
    error_message = "client_vpn_dns_configuration.mode must be none, vpc_resolver, or custom."
  }

  validation {
    condition = (
      var.client_vpn_dns_configuration.mode == "custom"
      ? (
        length(var.client_vpn_dns_configuration.custom_dns_servers) > 0 &&
        length(distinct(var.client_vpn_dns_configuration.custom_dns_servers)) == length(var.client_vpn_dns_configuration.custom_dns_servers) &&
        alltrue([
          for dns_server in var.client_vpn_dns_configuration.custom_dns_servers :
          can(cidrhost("${dns_server}/32", 0))
        ])
      )
      : length(var.client_vpn_dns_configuration.custom_dns_servers) == 0
    )
    error_message = "custom mode requires unique IPv4 DNS server addresses; other modes must leave custom_dns_servers empty."
  }
}
