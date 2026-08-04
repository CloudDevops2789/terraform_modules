##################################################################################################
# AWS Region
##################################################################################################
variable "aws_region" {
  description = "AWS Region used to validate the Network Firewall module."
  type        = string
  default     = "us-east-1"
}
variable "vpc_cidr" {
  description = "IPv4 CIDR block for the isolated module-test VPC."
  type        = string
  default     = "10.252.0.0/16"
}
