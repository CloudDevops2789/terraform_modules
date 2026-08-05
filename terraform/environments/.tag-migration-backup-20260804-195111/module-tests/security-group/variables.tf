# Exists so this test can be pointed at a different Region without editing
# code. Optional - a default is set, so plan/apply never prompts for it;
# terraform.tfvars can override it. Unrelated to any generated resource in
# this environment; this environment has none that can be overridden.
variable "aws_region" {
  description = "AWS Region this module test deploys into."
  type        = string
  default     = "us-east-1"
}
