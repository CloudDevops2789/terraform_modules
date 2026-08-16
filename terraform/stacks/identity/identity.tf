##################################################################################################
# IRE Identity Stack
##################################################################################################
#
# Intended lifecycle:
#   - independent from Platform destroy
#   - highly controlled
#   - persistent when administrative identity services are enabled
#
# Target capability:
#   AWS Managed Microsoft AD in the Core Recovery VPC.
#
# The Managed Microsoft AD resource is intentionally NOT enabled yet.
#
# Before enabling it, the project must approve how the directory administrator
# password is supplied and whether storing that secret in Terraform state is
# acceptable under the enterprise security model.
#
# Future dependency contract:
#
#   vpc_id =
#     var.platform_contract.core_recovery_vpc_id
#
#   subnet_ids =
#     var.platform_contract.directory_services_subnet_ids
#
##################################################################################################
