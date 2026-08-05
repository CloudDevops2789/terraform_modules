##################################################################################################
# Supporting Certificates
##################################################################################################
# The Client VPN module requires a server certificate and a root CA
# certificate chain to already exist in ACM - it does not issue
# certificates itself. When an operator supplies var.server_certificate_arn
# and var.root_certificate_chain_arn (see variables.tf), those existing ACM
# certificates are used instead and none of the resources below are
# created - this is the enterprise path, where certificates already exist
# and are managed outside this test.
#
# When those variables are left unset (the default, home lab path), this
# file generates a throwaway self-signed CA and server certificate with the
# tls provider and imports both into ACM, so the whole test can still run
# with one `terraform apply` and be torn down with one `terraform destroy`,
# without an operator manually issuing certificates first.
#
# `count = local.generate_certificates ? 1 : 0` on every resource here is
# what makes generation optional: 1 when certificates need to be created,
# 0 when the operator already provided ARNs. None of this is under test;
# it exists only to satisfy the module's certificate requirement.

############################################
# Root Certificate Authority
############################################

resource "tls_private_key" "ca" {
  count = local.generate_certificates ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca" {
  count = local.generate_certificates ? 1 : 0

  private_key_pem = tls_private_key.ca[0].private_key_pem

  subject {
    common_name  = local.certificates.ca_common_name
    organization = local.certificates.organization
  }

  validity_period_hours = local.certificates.validity_period_hours
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "key_encipherment",
    "digital_signature",
  ]
}

resource "aws_acm_certificate" "root_ca" {
  count = local.generate_certificates ? 1 : 0

  private_key      = tls_private_key.ca[0].private_key_pem
  certificate_body = tls_self_signed_cert.ca[0].cert_pem

  tags = local.org_tags
}

############################################
# Server Certificate
############################################

resource "tls_private_key" "server" {
  count = local.generate_certificates ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server" {

  count = local.generate_certificates ? 1 : 0

  private_key_pem = tls_private_key.server[0].private_key_pem

  subject {
    common_name  = local.certificates.server_common_name
    organization = local.certificates.organization
  }

  dns_names = [
    local.certificates.server_common_name
  ]
}

resource "tls_locally_signed_cert" "server" {
  count = local.generate_certificates ? 1 : 0

  cert_request_pem   = tls_cert_request.server[0].cert_request_pem
  ca_private_key_pem = tls_private_key.ca[0].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca[0].cert_pem

  validity_period_hours = local.certificates.validity_period_hours

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "server" {
  count = local.generate_certificates ? 1 : 0

  private_key       = tls_private_key.server[0].private_key_pem
  certificate_body  = tls_locally_signed_cert.server[0].cert_pem
  certificate_chain = tls_self_signed_cert.ca[0].cert_pem

  tags = local.org_tags
}
