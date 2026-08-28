############################################################
# AWS Managed Microsoft AD
#
# Provisions an AWS Managed Microsoft Active Directory
# within a caller-selected VPC and two private subnets.
#
# AWS manages the underlying Domain Controllers,
# replication, patching, and high availability.
# This module is responsible only for provisioning
# the directory service.
############################################################

resource "aws_directory_service_directory" "this" {

  ##########################################################
  # Creates an AWS Managed Microsoft Active Directory.
  ##########################################################

  name     = var.domain_name
  password = var.password
  edition  = var.edition
  type     = "MicrosoftAD"

  enable_directory_data_access = var.enable_directory_data_access

  vpc_settings {
    vpc_id     = var.vpc_id
    subnet_ids = var.subnet_ids
  }

  # Directory password rotation is operationally owned outside Terraform.
  # Ignoring password drift prevents credential rotation from replacing the directory.
  lifecycle {
    ignore_changes = [password]
  }

  tags = var.tags
}
