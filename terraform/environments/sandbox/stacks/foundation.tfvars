################################################################################
# Persistent Foundation Configuration
################################################################################
# Stable environment configuration is Git controlled. AWS Region and stable
# KMS administrator ARNs are supplied by the approved AAP runtime contract.

name_prefix = "ire-sandbox-foundation"

air_gapped_min_retention_days = 30
air_gapped_max_retention_days = 365

network_firewall_log_group_prefix = "/aws/network-firewall/ire-sandbox-centralized-inspection"
