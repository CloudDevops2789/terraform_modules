################################################################################
# Security Group Policy
################################################################################
# Defines allowed traffic to Sandbox security groups.
#
# Read ingress rules as:
#   ALLOW <peer> -> <security_group> ON <protocol>/<port>
#
# security_group = destination
# peer           = source
#
# peer_type:
#   security_group = source SG
#   vpc            = source VPC
#   cidr           = explicit source CIDR
#
# Examples:
#   Client VPN -> Management:
#     security_group = "management"
#     peer_type      = "security_group"
#     peer           = "management"
#
#   Core -> Management:
#     security_group = "management"
#     peer_type      = "vpc"
#     peer           = "core_recovery"
#
# Routing / Network Firewall must also allow the traffic.
################################################################################


security_group_rules = [
  {
    name           = "management-ssh-from-core"
    direction      = "ingress"
    security_group = "management"
    protocol       = "tcp"
    from_port      = 22
    to_port        = 22
    peer_type      = "vpc"
    peer           = "core_recovery"
    description    = "Allow SSH from Core Recovery to Management"
  },
  {
    name           = "management-egress"
    direction      = "egress"
    security_group = "management"
    protocol       = "-1"
    peer_type      = "cidr"
    peer           = "0.0.0.0/0"
    description    = "Allow management tier outbound traffic"
  },
  {
    name           = "core-ssh-from-recovery-access"
    direction      = "ingress"
    security_group = "core"
    protocol       = "tcp"
    from_port      = 22
    to_port        = 22
    peer_type      = "vpc"
    peer           = "recovery_access"
    description    = "Allow SSH from Recovery Access to Core Recovery"
  },
  {
    name           = "core-ssh-from-protected-data"
    direction      = "ingress"
    security_group = "core"
    protocol       = "tcp"
    from_port      = 22
    to_port        = 22
    peer_type      = "vpc"
    peer           = "protected_data"
    description    = "Allow SSH from Protected Data to Core Recovery"
  },
  {
    name           = "core-egress"
    direction      = "egress"
    security_group = "core"
    protocol       = "-1"
    peer_type      = "cidr"
    peer           = "0.0.0.0/0"
    description    = "Allow Core Recovery tier outbound traffic"
  },
  {
    name           = "protected-ssh"
    direction      = "ingress"
    security_group = "protected"
    protocol       = "tcp"
    from_port      = 22
    to_port        = 22
    peer_type      = "vpc"
    peer           = "core_recovery"
    description    = "Allow SSH from Core Recovery to Protected Data"
  },
  {
    name           = "protected-egress"
    direction      = "egress"
    security_group = "protected"
    protocol       = "-1"
    peer_type      = "cidr"
    peer           = "0.0.0.0/0"
    description    = "Allow Protected Data tier outbound traffic"
  },
]


################################################################################
# AWS Network Firewall Policy
################################################################################
# PURPOSE
# -------
# Defines the approved traffic paths between IRE network zones when:
#
#   network_inspection_mode = "firewall"
#
# Rules are evaluated in the listed order because AWS Network Firewall uses
# STRICT_ORDER.
#
# Read each rule as:
#
#   <ACTION> <PROTOCOL> <SOURCE ZONE> -> <DESTINATION ZONE>
#
# Example:
#
#   action           = "pass"
#   protocol         = "ip"
#   source_zone      = "recovery_access"
#   destination_zone = "core_recovery"
#
# Means:
#
#   ALLOW all IP traffic from Recovery Access -> Core Recovery
#
# Logical zone names are automatically resolved to the CIDRs defined in the
# environment network configuration.
#
# Approved IRE trust paths:
#
#   Recovery Access <-> Core Recovery
#   Core Recovery   <-> Protected Data
#
# There is intentionally NO direct:
#
#   Recovery Access <-> Protected Data
#
# NOTE:
# These rules are not used to inspect traffic when:
#
#   network_inspection_mode = "bypass"
#
# In bypass mode the approved VPC relationships are routed directly through TGW.
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
