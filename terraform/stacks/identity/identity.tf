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
#     local.identity_platform_placement.vpc_id
#
#   subnet_ids =
#     local.identity_platform_placement.subnet_ids
#
##################################################################################################
