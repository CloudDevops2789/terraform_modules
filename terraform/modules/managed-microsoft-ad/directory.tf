############################################################
# AWS Managed Microsoft AD
#
# Provisions an AWS Managed Microsoft Active Directory
# within an existing Core Recovery VPC.
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

  vpc_settings {
    vpc_id     = var.vpc_id
    subnet_ids = var.subnet_ids
  }

  tags = var.tags
}