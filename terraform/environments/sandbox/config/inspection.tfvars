################################################################################
# Inspection Stack
################################################################################
#
# Runtime dependencies are resolved by AAP:
#
#   Platform   -> inspection_contract
#   Persistent -> network_firewall_logging_kms_key_arn
#
# Never copy those upstream resource identifiers into this file.
################################################################################

################################################################################
# Naming
################################################################################

naming = {
  organization             = "fv"
  project                  = "ire"
  project_display_name     = "IRE"
  environment              = "sandbox"
  environment_display_name = "Sandbox"

  region_code = null
  suffix      = null
}

################################################################################
# Inspection Resource-Name Overrides
################################################################################
#
# Empty map preserves the existing derived AWS resource names.
# Changing an existing name may require replacement and must be plan-reviewed.
################################################################################

resource_name_overrides = {}

################################################################################
# AWS Network Firewall Policy
################################################################################
#
# Rules use logical Platform VPC keys. Inspection resolves those keys to CIDRs
# from inspection_contract rather than duplicating network allocation here.
#
# Approved trust paths:
#
#   Recovery Access <-> Core Recovery
#   Core Recovery   <-> Protected Data
#
# No direct Recovery Access <-> Protected Data rule is defined.
################################################################################

network_firewall_rules = [
  {
    action           = "pass"
    protocol         = "ip"
    source_zone      = "recovery_access"
    destination_zone = "core_recovery"
    description      = "Allow Recovery Access to Core Recovery"
    sid              = 3100001
  },
  {
    action           = "pass"
    protocol         = "ip"
    source_zone      = "core_recovery"
    destination_zone = "recovery_access"
    description      = "Allow Core Recovery to Recovery Access"
    sid              = 3100002
  },
  {
    action           = "pass"
    protocol         = "ip"
    source_zone      = "core_recovery"
    destination_zone = "protected_data"
    description      = "Allow Core Recovery to Protected Data"
    sid              = 3100003
  },
  {
    action           = "pass"
    protocol         = "ip"
    source_zone      = "protected_data"
    destination_zone = "core_recovery"
    description      = "Allow Protected Data to Core Recovery"
    sid              = 3100004
  }
]

################################################################################
# Network Firewall Logging
################################################################################
#
# Network Firewall ALERT and FLOW logging is enabled for Sandbox validation.
# When enabled, the optional KMS ARN comes from Persistent through AAP.
################################################################################

network_firewall_logging_enabled = true
