##################################################################################################
# Short-Lived Test Certificate Authority
##################################################################################################
# This private key is stored in Terraform state. It is intentionally short-lived and must never be
# reused outside this isolated module test.
resource "tls_private_key" "outbound_ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "tls_self_signed_cert" "outbound_ca" {
  private_key_pem       = tls_private_key.outbound_ca.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = 24
  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature"
  ]
  subject {
    common_name  = "AWS IRE Network Firewall Module Test CA"
    organization = "AWS IRE Module Test"
  }
}
resource "aws_acm_certificate" "outbound_ca" {
  certificate_body = tls_self_signed_cert.outbound_ca.cert_pem
  private_key      = tls_private_key.outbound_ca.private_key_pem
  tags             = local.default_tags
  lifecycle {
    create_before_destroy = true
  }
}
