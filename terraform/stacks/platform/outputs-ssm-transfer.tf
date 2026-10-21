##################################################################################################
# Ansible over Systems Manager Transfer Contract
##################################################################################################

output "ssm_transfer_bucket_name" {
  description = "Private S3 bucket used for transient Ansible over SSM transfers, or null when disabled."
  value = (
    var.ssm_transfer_bucket_enabled
    ? module.ssm_transfer_bucket[0].name
    : null
  )
}

output "ssm_transfer_kms_key_arn" {
  description = "KMS key ARN protecting transient Ansible over SSM transfer objects, or null when disabled."
  value = (
    var.ssm_transfer_bucket_enabled
    ? module.ssm_transfer_kms[0].key_arn
    : null
  )
}
