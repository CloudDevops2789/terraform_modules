############################################################
# KMS Key
############################################################

output "key_id" {
  description = "The unique identifier of the KMS key."
  value       = aws_kms_key.this.key_id
}

output "key_arn" {
  description = "The ARN of the KMS key."
  value       = aws_kms_key.this.arn
}

############################################################
# KMS Alias
############################################################

output "alias_name" {
  description = "The name of the KMS alias."
  value       = aws_kms_alias.this.name
}

output "alias_arn" {
  description = "The ARN of the KMS alias."
  value       = aws_kms_alias.this.arn
}