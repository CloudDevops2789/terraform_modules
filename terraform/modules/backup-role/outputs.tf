############################################
# IAM Role Outputs
############################################

output "id" {

  description = "The ID of the IAM Role."

  value = aws_iam_role.this.id

}

output "arn" {

  description = "The ARN of the IAM Role."

  value = aws_iam_role.this.arn

}

output "name" {

  description = "The name of the IAM Role."

  value = aws_iam_role.this.name

}