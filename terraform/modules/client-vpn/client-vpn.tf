############################################
# Client VPN Endpoint
############################################

# The Client VPN endpoint is the managed VPN server provided by AWS.
#
# Clients establish a TLS connection to this endpoint using the AWS
# Client VPN application (OpenVPN-based).
#
# Authentication is performed using Mutual Authentication:
#
# Client
#    │
# Client Certificate
#    │
# AWS Client VPN Endpoint
#    │
# Server Certificate (ACM)
#    │
# Trusted Root CA
#
# At this stage the module creates ONLY the endpoint itself.
#
# Network associations, authorization rules and routes are created
# separately to keep the deployment modular and easier to troubleshoot.
resource "aws_ec2_client_vpn_endpoint" "this" {

  description = var.name

  ############################################
  # Client Address Pool
  ############################################

  # CIDR block from which VPN clients receive an IP address after
  # connecting.
  #
  # Example:
  #
  # VPC
  # 10.100.0.0/16
  #
  # Client VPN
  # 192.168.0.0/16
  #
  # These ranges MUST NOT overlap.
  client_cidr_block = var.client_cidr_block

  ############################################
  # VPC
  ############################################

  # The VPC that contains the target network associations
  # and the security groups attached to the Client VPN endpoint.
  vpc_id = var.vpc_id

  ############################################
  # Server Certificate
  ############################################

  # Certificate presented by the VPN endpoint during TLS negotiation.
  #
  # This certificate must already exist in ACM.
  server_certificate_arn = var.server_certificate_arn

  ############################################
  # Authentication
  ############################################

  # Authentication method used by the Client VPN endpoint.
  # This module supports two methods:
  # - certificate: Mutual Authentication using client certificates.
  # - federated: Federated Authentication using SAML 2.0.
  authentication_options {
    type = (
      var.authentication_type == "federated"
      ? "federated-authentication"
      : "certificate-authentication"
    )

    root_certificate_chain_arn = (
      var.authentication_type == "certificate"
      ? var.root_certificate_chain_arn
      : null
    )

    saml_provider_arn = (
      var.authentication_type == "federated"
      ? var.saml_provider_arn
      : null
    )
  }

  # Enforce the inputs required by each authentication mode.
  lifecycle {
    precondition {
      condition = (
        var.authentication_type != "certificate" ||
        try(length(trimspace(var.root_certificate_chain_arn)) > 0, false)
      )

      error_message = "root_certificate_chain_arn must be provided when authentication_type is certificate."
    }

    precondition {
      condition = (
        var.authentication_type != "federated" ||
        try(length(trimspace(var.saml_provider_arn)) > 0, false)
      )

      error_message = "saml_provider_arn must be provided when authentication_type is federated."
    }
  }
  ############################################
  # Connection Logging
  ############################################

  # Publish VPN connection logs to CloudWatch.
  #
  # Logging is highly recommended for troubleshooting and auditing.
  connection_log_options {

    enabled = var.enable_connection_logging

    cloudwatch_log_group  = aws_cloudwatch_log_group.this.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.this.name
  }
  ############################################
  # VPN Configuration
  ############################################

  split_tunnel       = var.split_tunnel
  transport_protocol = lower(var.transport_protocol)
  vpn_port           = var.vpn_port

  ############################################
  # DNS
  ############################################

  dns_servers = var.dns_servers

  ############################################
  # Session Management
  ############################################

  session_timeout_hours = var.session_timeout_hours

  ############################################
  # Security Groups
  ############################################

  # These security groups are attached to the ENIs AWS creates when
  # the endpoint is associated with a subnet.
  security_group_ids = var.security_group_ids

  ############################################
  # Tags
  ############################################

  tags = local.default_tags
}