# FOR_EACH: creates one subnet per entry of the var.public_subnets map.
# each.key is the map key ("public-a"), each.value the CIDR string. Unlike
# count, for_each addresses resources by key, so adding/removing one subnet
# never shifts (and thus destroys/recreates) the others.
# map_public_ip_on_launch=true auto-assigns public IPs to instances launched
# here - what makes these subnets 'public' besides the IGW route.
resource "aws_subnet" "public" {

  for_each = var.public_subnets

  vpc_id = aws_vpc.this.id

  cidr_block = each.value

  # Spreads subnets across AZs deterministically: index() finds this subnet's
  # position in the ordered key list, which selects the matching AZ from the
  # locals list (subnet 0 -> AZ 0, subnet 1 -> AZ 1, ...).
  availability_zone = local.availability_zones[
    index(local.public_subnet_keys, each.key)
  ]

  map_public_ip_on_launch = false # true when we want public IPs on instances in this subnet

  # merge() combines maps left-to-right; later keys win. Common tags come
  # first, then subnet-specific Name/Tier overrides.
  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-${each.key}"
      Tier = "Public"
    }
  )

}

# Private subnets: same for_each pattern but NO map_public_ip_on_launch and
# (see routing.tf) no route to an Internet Gateway. Workloads and TGW
# attachments live here.
resource "aws_subnet" "private" {

  for_each = var.private_subnets

  vpc_id = aws_vpc.this.id

  cidr_block = each.value

  availability_zone = local.availability_zones[
    index(local.private_subnet_keys, each.key)
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-${each.key}"
      Tier = "Private"
    }
  )

}
