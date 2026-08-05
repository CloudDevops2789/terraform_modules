# Exists so this test can be pointed at a different Region without editing
# code. Optional - a default is set, so plan/apply never prompts for it;
# terraform.tfvars can override it. Unrelated to generated resources; it has
# nothing to do with certificates or passwords.
variable "aws_region" {
  description = "AWS Region this module test deploys into."
  type        = string
  default     = "us-east-1"
}

# Named to match the same variable in sandbox (terraform/environments/sandbox)
# so anyone familiar with sandbox recognizes it immediately here. The
# directory password cannot be a static value in locals.tf - it is a secret,
# and secrets never belong in version control. It is declared here with no
# default, so Terraform refuses to apply without an operator supplying one
# via terraform.tfvars (untracked) or TF_VAR_managed_ad_password. It is
# required, not optional: AWS Managed Microsoft AD has no supporting
# resource that could generate a password on its behalf, so this
# environment cannot supply an automatic default the way client-vpn does
# for certificates.
variable "managed_ad_password" {
  description = "Password for the AWS Managed Microsoft AD directory administrator account."
  type        = string
  sensitive   = true
}
