locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  org_required_tags = {
    "org_it_cost_center"       = var.org_it_cost_center
    "org_department"           = var.org_department
    "org_cmdb_calculated_app"  = var.org_cmdb_calculated_app
    "org_business_criticality" = var.org_business_criticality
    "org_environment"          = var.org_environment
    "org_data_classification"  = var.org_data_classification
    "org_project_name"         = var.org_project_name
    "org_managed_by"           = var.org_managed_by
  }

  org_tags = merge(
    var.org_additional_tags,
    local.org_required_tags
  )

  ##################################################################################################
  # Supporting VPC
  ##################################################################################################
  # The Client VPN module creates Elastic Network Interfaces inside real
  # subnets of a real VPC. A minimal VPC with one private subnet exists
  # only to give the module a network to associate with; the VPC itself is
  # not under test.
  vpc = {
    vpc_name   = "module-test-client-vpn-vpc"
    cidr_block = "10.254.0.0/16"

    route_tables = {
      private-a = {
        group = "supporting"
      }
    }

    subnets = {
      private-a = {
        cidr_block              = "10.254.11.0/24"
        availability_zone_index = 0
        group                   = "supporting"
        route_table_key         = "private-a"
      }
    }
  }

  ##################################################################################################
  # Supporting Security Group
  ##################################################################################################
  # The Client VPN endpoint requires a security group for traffic leaving
  # its ENIs toward VPC resources. Only the minimum required security
  # group is created because security groups are not the focus of this
  # test.
  security_group = {
    description = "Module test - Client VPN"
  }

  ##################################################################################################
  # Supporting Certificates
  ##################################################################################################
  # The Client VPN module requires ACM certificate ARNs that must already
  # exist - it does not create certificates itself. By default (home lab
  # use), a throwaway self-signed CA and server certificate are generated
  # with the tls provider and imported into ACM, so this test can run
  # start-to-finish with a single `terraform apply`, without an operator
  # manually issuing certificates first. Certificate issuance itself is not
  # under test. In enterprise use, an operator can instead supply
  # var.server_certificate_arn and var.root_certificate_chain_arn (see
  # variables.tf) to point this test at existing ACM certificates, and
  # generation is skipped entirely - see "Certificate Source" below.
  certificates = {
    ca_common_name        = "AWS IRE Root CA"
    server_common_name    = "vpn.aws-ire.lab"
    organization          = "AWS-IRE"
    validity_period_hours = 8760 # 1 year
  }

  ##################################################################################################
  # Certificate Source
  ##################################################################################################
  # Certificate authentication requires both a server certificate and a
  # client root CA. Federated authentication requires only the server
  # certificate; when no server certificate is supplied, this test generates
  # a throwaway CA and server certificate pair, but the CA is not passed to
  # the Client VPN authentication configuration.
  generate_certificates = (
    var.server_certificate_arn == null ||
    (
      var.authentication_type == "certificate" &&
      var.root_certificate_chain_arn == null
    )
  )

  # The ARNs actually passed to the client-vpn module: whatever the
  # operator supplied, falling back to the throwaway certificates
  # generated in certificates.tf when they did not.
  effective_server_certificate_arn = (
    var.server_certificate_arn != null
    ? var.server_certificate_arn
    : try(aws_acm_certificate.server[0].arn, null)
  )

  effective_root_certificate_chain_arn = (
    var.root_certificate_chain_arn != null
    ? var.root_certificate_chain_arn
    : try(aws_acm_certificate.root_ca[0].arn, null)
  )
  ##################################################################################################
  # Client VPN Under Test
  ##################################################################################################
  # Static Client VPN configuration used to validate certificate-based
  # authentication and endpoint creation. Values mirror the sandbox
  # defaults so this test exercises the same code paths sandbox relies on.
  client_vpn = {
    name                  = "module-test-client-vpn"
    client_cidr_block     = "192.168.0.0/16"
    split_tunnel          = true
    transport_protocol    = "udp"
    vpn_port              = 443
    dns_servers           = []
    session_timeout_hours = 8
    authorize_all_groups  = true
  }
}
