module "kms" {
  source = "../../../modules/kms"

  description = "KMS module test"

  alias = "kms-test"

  tags = {
    Environment = "Test"
    ManagedBy   = "Terraform"
  }
}