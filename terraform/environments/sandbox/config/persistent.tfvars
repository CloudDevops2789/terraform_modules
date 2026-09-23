################################################################################
# Persistent Resources Configuration
################################################################################
# Capability flags are Git controlled. AWS Region and stable KMS administrator
# ARNs are supplied by the approved AAP runtime contract when required.

name_prefix = "fv-ire-sandbox-persistent"

backup_vaults_enabled                = true
network_firewall_logging_kms_enabled = true

# Enable later for certificate lifecycle testing.
client_vpn_pki_artifacts_enabled = true

air_gapped_min_retention_days = 30
air_gapped_max_retention_days = 365

network_firewall_log_group_prefix = "/aws/network-firewall/fv-ire-sandbox-centralized-inspection"
