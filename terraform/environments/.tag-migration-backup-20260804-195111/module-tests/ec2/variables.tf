# Exists so this test can be pointed at a different Region without editing
# code. Optional - a default is set, so plan/apply never prompts for it;
# terraform.tfvars can override it. Unrelated to key pair generation below.
variable "aws_region" {
  description = "AWS Region this module test deploys into."
  type        = string
  default     = "us-east-1"
}

# Named to match the same variable in sandbox (terraform/environments/sandbox)
# so anyone familiar with sandbox recognizes it immediately here.
#
# Required, not optional - unlike client-vpn's certificates, there is no
# safe way to auto-generate a real SSH key pair's public half as a static
# default (a hardcoded public key committed to this repository would be a
# key everyone could use), so an operator must always supply the path to
# their own public key. This does not override a generated resource - it
# is the only source for the key-pair module's input in compute.tf, which
# in turn lets this test exercise the ec2 module's `key_name` attribute
# instead of leaving it at its default (unset).
variable "public_key_path" {
  description = "Path to the SSH public key used to create the supporting key pair."
  type        = string
}
