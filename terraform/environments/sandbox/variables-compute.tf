##################################################################################################
# Compute Variables
##################################################################################################

variable "public_key_path" {
  description = "Path to the SSH public key"
  type        = string
}

variable "ami_id" {
  description = "EC2 AMI ID"
  type        = string
}

#### Tagging Variables #######
