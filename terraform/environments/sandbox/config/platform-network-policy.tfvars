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
