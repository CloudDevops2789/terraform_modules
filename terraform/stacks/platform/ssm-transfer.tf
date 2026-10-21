##################################################################################################
# Ansible over Systems Manager Transfer Channel
#
# This bucket contains transient Ansible module/file payloads used by the
# amazon.aws.aws_ssm connection plugin.
#
# It is intentionally:
#   - private;
#   - KMS encrypted;
#   - non-versioned;
#   - lifecycle-expired;
#   - independent of Recovery workload lifecycle.
##################################################################################################

data "aws_caller_identity" "ssm_transfer" {}

locals {
  ssm_transfer_bucket_name = join(
    "-",
    compact([
      var.naming.organization,
      var.naming.project,
      var.naming.environment,
      local.effective_region_code,
      data.aws_caller_identity.ssm_transfer.account_id,
      "ansible-ssm-transfer"
    ])
  )

  ssm_transfer_kms_alias = join(
    "-",
    compact([
      var.naming.organization,
      var.naming.project,
      var.naming.environment,
      local.effective_region_code,
      "ansible-ssm-transfer"
    ])
  )
}

module "ssm_transfer_kms" {
  count = var.ssm_transfer_bucket_enabled ? 1 : 0

  source = "../../modules/kms"

  description = "KMS key for transient IRE Ansible over SSM transfer objects."
  alias       = local.ssm_transfer_kms_alias

  # Never persist an ephemeral AAP/AWX AssumeRole session in the key policy.
  bootstrap_current_caller = false

  key_administrators  = var.ssm_transfer_kms_key_administrators
  key_user_principals = var.ssm_transfer_kms_key_users

  tags = merge(
    local.org_tags,
    {
      service_name = "ansible-ssm-transfer"
    }
  )
}

module "ssm_transfer_bucket" {
  count = var.ssm_transfer_bucket_enabled ? 1 : 0

  source = "../../modules/s3-private-bucket"

  name        = local.ssm_transfer_bucket_name
  kms_key_arn = module.ssm_transfer_kms[0].key_arn

  # Transient SSM transport data must not accumulate historical versions.
  versioning_enabled = false

  # Terraform may clean up residual transfer objects when this optional
  # management-plane capability is intentionally removed.
  force_destroy = true

  object_expiration_days = var.ssm_transfer_object_expiration_days

  tags = merge(
    local.org_tags,
    {
      service_name = "ansible-ssm-transfer"
    }
  )
}
