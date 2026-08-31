################################################################################
# Fairview Remote Access desired state
################################################################################

# Creation still requires Platform, Identity and AD user/group bootstrap to
# complete first. AAP supplies the approved ACM server certificate ARN and the
# Managed AD VPN-group SID at runtime.
remote_access_enabled = true

name                = "fv-ire-sandbox-remote-access"
client_cidr_block   = "172.30.240.0/22"
authentication_type = "directory"

# Future combined authentication changes only the reviewed mode below and
# requires client_root_certificate_chain_arn at runtime:
# authentication_type = "directory_and_mutual"

network_binding = {
  vpc_key               = "recovery_access"
  subnet_group          = "client-vpn"
  required_subnet_count = 2
}

dns_configuration = {
  mode = "vpc_resolver"
}

authorization_vpc_keys = [
  "recovery_access"
]

# Client VPN IPv4 traffic is SNATed to an association-subnet ENI address.
# These ingress rules therefore resolve source CIDRs from the selected Platform
# subnet group, never from client_cidr_block.
target_ingress_rules = {
  management-ssh = {
    security_group_key = "management"
    protocol           = "tcp"
    from_port          = 22
    to_port            = 22
    description        = "SSH from Client VPN association subnets"
  }

  management-rdp = {
    security_group_key = "management"
    protocol           = "tcp"
    from_port          = 3389
    to_port            = 3389
    description        = "RDP from Client VPN association subnets"
  }

  management-icmp = {
    security_group_key = "management"
    protocol           = "icmp"
    from_port          = 8
    to_port            = -1
    description        = "ICMP echo from Client VPN association subnets"
  }
}

endpoint_egress_rules = {
  management-ssh = {
    destination_vpc_key = "recovery_access"
    protocol            = "tcp"
    from_port           = 22
    to_port             = 22
    description         = "SSH to approved Recovery Access resources"
  }

  management-rdp = {
    destination_vpc_key = "recovery_access"
    protocol            = "tcp"
    from_port           = 3389
    to_port             = 3389
    description         = "RDP to approved Recovery Access resources"
  }

  management-icmp = {
    destination_vpc_key = "recovery_access"
    protocol            = "icmp"
    from_port           = 8
    to_port             = -1
    description         = "ICMP echo to approved Recovery Access resources"
  }
}
