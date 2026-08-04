locals {
  availability_zone = data.aws_availability_zones.available.names[0]
  subnet_cidrs = {
    workload = cidrsubnet(var.vpc_cidr, 8, 10)
    firewall = cidrsubnet(var.vpc_cidr, 8, 20)
    transit  = cidrsubnet(var.vpc_cidr, 8, 30)
  }
  default_tags = {
    TestedModule = "network-firewall-routing"
  }
  firewall_policies = {
    inspection = {
      name        = "module-test-network-firewall-routing-policy"
      description = "Minimal policy supporting the Network Firewall routing module test."
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
