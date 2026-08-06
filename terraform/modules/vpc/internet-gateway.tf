##################################################################################################
# Optional Internet Gateway
##################################################################################################
#
# The Internet Gateway is created only when create_internet_gateway is true.
#
# Creating the gateway does not create a default route and does not expose any
# subnet automatically.
#
# A consuming environment may later use this capability for controlled egress
# patterns such as:
#
# - Island Browser outbound access;
# - NAT Gateway egress;
# - Network Firewall-inspected internet access;
# - public ingress where explicitly approved.
#
# The environment remains responsible for deciding which route table, if any,
# receives a route to this gateway.

resource "aws_internet_gateway" "this" {
  count = var.create_internet_gateway ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )
}
