# Environment-level input. Because a `default` is set, running plan/apply
# never prompts for it; terraform.tfvars can override it. No `type` is
# declared, so Terraform infers it ("any" constrained by the default's type).
variable "aws_region" {

  default = "us-east-1"

}

variable "public_key_path" {
  description = "Path to the SSH public key"
  type        = string
}

variable "server_certificate_arn" {
  description = "ACM server certificate ARN."
  type        = string
}

variable "root_certificate_chain_arn" {
  description = "ACM root CA certificate ARN."
  type        = string
}

variable "managed_ad_password" {
  description = "Password for AWS Managed Microsoft AD"
  type        = string
  sensitive   = true
}

variable "ami_id" {
  description = "EC2 AMI ID"
  type        = string
}