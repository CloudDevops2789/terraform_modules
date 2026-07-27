output "instance_ids" {
  value = module.ec2.instance_ids
}

output "private_ips" {
  value = module.ec2.private_ips
}

output "public_ips" {
  value = module.ec2.public_ips
}


############################################
# Backup Plan Outputs
############################################

output "backup_plan_id" {

  description = "The ID of the Backup Plan."

  value = module.backup_plan.id

}

output "backup_plan_arn" {

  description = "The ARN of the Backup Plan."

  value = module.backup_plan.arn

}

output "backup_plan_version" {

  description = "The version of the Backup Plan."

  value = module.backup_plan.version

}