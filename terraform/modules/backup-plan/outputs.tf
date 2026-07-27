############################################
# Backup Plan Outputs
############################################

output "id" {

  description = "The ID of the Backup Plan."

  value = aws_backup_plan.this.id

}

output "arn" {

  description = "The ARN of the Backup Plan."

  value = aws_backup_plan.this.arn

}

output "version" {

  description = "The version ID of the Backup Plan."

  value = aws_backup_plan.this.version

}