################################################################################
# Persistent Resources Configuration
################################################################################
# Capability flags are Git controlled. AWS Region and stable KMS administrator
# ARNs are supplied by the approved AAP runtime contract when required.

# Retain the established AWS naming prefix during the stack rename.
name_prefix = "fv-ire-sandbox-persistent"

# Safe home-lab defaults. Enable independently to exercise managed resources.
backup_vaults_enabled                = false
network_firewall_logging_kms_enabled = false

air_gapped_min_retention_days = 30
air_gapped_max_retention_days = 365

network_firewall_log_group_prefix = "/aws/network-firewall/fv-ire-sandbox-centralized-inspection"
