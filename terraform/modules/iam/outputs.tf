##################################################################################################
# IAM Module Outputs
##################################################################################################

output "roles" {
  description = "IAM roles created by this module."

  value = {
    for key, role in aws_iam_role.this :
    key => {
      name      = role.name
      arn       = role.arn
      unique_id = role.unique_id
    }
  }
}

output "role_names" {
  description = "IAM role names keyed by logical role key."
  value = {
    for key, role in aws_iam_role.this :
    key => role.name
  }
}

output "role_arns" {
  description = "IAM role ARNs keyed by logical role key."
  value = {
    for key, role in aws_iam_role.this :
    key => role.arn
  }
}

output "instance_profile_names" {
  description = "IAM instance-profile names keyed by logical role key."
  value = {
    for key, profile in aws_iam_instance_profile.this :
    key => profile.name
  }
}

output "instance_profile_arns" {
  description = "IAM instance-profile ARNs keyed by logical role key."
  value = {
    for key, profile in aws_iam_instance_profile.this :
    key => profile.arn
  }
}
