##################################################################################################
# AWS Region
##################################################################################################
variable "aws_region" {
  description = "AWS Region used to validate the Network Firewall rule group module."
  type        = string
  default     = "us-east-1"
}
