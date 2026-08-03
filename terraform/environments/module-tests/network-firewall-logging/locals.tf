locals {
  availability_zone = data.aws_availability_zones.available.names[0]
  default_tags = {
    TestedModule = "network-firewall-logging"
  }
  firewall_policies = {
    inspection = {
      name        = "module-test-network-firewall-logging-policy"
      description = "Minimal policy supporting the Network Firewall logging module test."
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
