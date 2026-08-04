locals {
  ##################################################################################################
  # Test Topology
  ##################################################################################################
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  firewall_subnets = {
    for index, availability_zone in local.availability_zones :
    availability_zone => {
      availability_zone = availability_zone
      cidr_block        = cidrsubnet(var.vpc_cidr, 8, index)
    }
  }
  default_tags = {
    TestedModule = "network-firewall"
  }
  ##################################################################################################
  # Supporting Firewall Policy
  ##################################################################################################
  firewall_policies = {
    inspection = {
      name        = "module-test-network-firewall-policy"
      description = "Minimal policy supporting the Network Firewall module test."
      firewall_policy = {
        stateless_default_actions = [
          "aws:forward_to_sfe"
        ]
        stateless_fragment_default_actions = [
          "aws:forward_to_sfe"
        ]
      }
    }
  }
}
