################################################################################
# Inspection Stack
################################################################################
#
# The Inspection stack currently receives its infrastructure dependencies from:
#
#   Platform   -> inspection_contract
#   Persistent -> network_firewall_logging_kms_key_arn
#
# Those values are resolved by AAP and must not be copied into this file.
#
# Firewall policy, naming, tagging and logging configuration will move here only
# when Network Firewall ownership is transferred from Platform.
################################################################################
