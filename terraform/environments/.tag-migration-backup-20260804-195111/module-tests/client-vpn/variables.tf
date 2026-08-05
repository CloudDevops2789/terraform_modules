# Exists so this test can be pointed at a different Region without editing
# code. Optional - a default is set, so plan/apply never prompts for it;
# terraform.tfvars can override it. Unrelated to certificate generation.
variable "aws_region" {
  description = "AWS Region this module test deploys into."
  type        = string
  default     = "us-east-1"
}

# Named to match the same variable in sandbox (terraform/environments/sandbox)
# so anyone familiar with sandbox recognizes it immediately here.
#
# Optional. Left unset (the default), this environment generates a
# throwaway self-signed server certificate and imports it into ACM itself
# (see certificates.tf) - the home lab path, where nothing needs to exist
# beforehand and `terraform apply` is fully self-contained.
#
# Supplying a real ACM certificate ARN here overrides that generated
# certificate and switches this test to the enterprise path: it validates
# the client-vpn module against certificates already issued and managed
# outside this test, exactly as a production deployment would use it.
#
# Must be supplied together with root_certificate_chain_arn - a server
# certificate not signed by the supplied root will fail at apply time.
variable "server_certificate_arn" {
  description = "Existing ACM server certificate ARN. Leave unset to auto-generate a throwaway certificate instead."
  type        = string
  default     = null
}

# Named to match the same variable in sandbox (terraform/environments/sandbox)
# so anyone familiar with sandbox recognizes it immediately here.
#
# Optional. Left unset (the default), this environment generates a
# throwaway self-signed root CA and imports it into ACM itself (see
# certificates.tf) - the home lab path, where nothing needs to exist
# beforehand and `terraform apply` is fully self-contained.
#
# Supplying a real ACM root CA certificate chain ARN here overrides that
# generated CA and switches this test to the enterprise path: it validates
# the client-vpn module against a CA already issued and managed outside
# this test, exactly as a production deployment would use it.
#
# Must be supplied together with server_certificate_arn - see that
# variable's description.
variable "root_certificate_chain_arn" {
  description = "Existing ACM root CA certificate chain ARN. Leave unset to auto-generate a throwaway CA instead."
  type        = string
  default     = null
}
