##################################################################################################
# Inspection Dependency Resolution
##################################################################################################
#
# These locals provide readable names for the two upstream lifecycle contracts.
#
# No AWS resources are created by this skeleton. The locals establish the
# reference path that the future Network Firewall composition will consume:
#
#   Platform state
#     -> inspection_contract
#     -> var.inspection_contract
#     -> local.inspection_topology
#
#   Persistent state
#     -> network_firewall_logging_kms_key_arn
#     -> var.persistent_resources
#     -> local.network_firewall_logging_kms_key_arn
##################################################################################################

locals {
  inspection_topology = var.inspection_contract

  network_firewall_logging_kms_key_arn = try(
    var.persistent_resources.network_firewall_logging_kms_key_arn,
    null
  )
}
