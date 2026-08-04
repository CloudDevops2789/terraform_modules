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

#### Tagging Variables ###

variable "org_it_cost_center" {
  type = string
}

variable "org_department" {
  type = string
}

variable "org_cmdb_calculated_app" {
  type = string
}

variable "org_business_criticality" {
  type = string
}

variable "org_environment" {
  type = string
}

variable "org_data_classification" {
  type = string
}

variable "project_name" {
  type = string
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}