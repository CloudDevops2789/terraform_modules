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