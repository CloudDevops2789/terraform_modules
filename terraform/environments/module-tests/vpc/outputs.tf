# Confirms the module produced a usable VPC and subnet - the concrete
# proof that "can this module deploy successfully?" is yes.
output "vpc_id" {
  description = "ID of the VPC created by the module under test."
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC created by the module under test."
  value       = module.vpc.vpc_cidr
}

output "private_subnet_ids" {
  description = "IDs of the private subnets created by the module under test."
  value       = module.vpc.private_subnet_ids
}
