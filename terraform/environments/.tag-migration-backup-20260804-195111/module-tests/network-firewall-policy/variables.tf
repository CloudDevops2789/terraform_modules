##################################################################################################
# AWS Region
##################################################################################################
variable "aws_region" {
  description = "AWS Region used to validate the Network Firewall policy module."
  type        = string
  default     = "us-east-1"
}
