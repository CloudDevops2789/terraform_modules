################################################################################
# Terraform Backend
#
# Backend values are intentionally not hardcoded here.
#
# AAP/common lifecycle execution supplies:
#   terraform_backend_bucket
#   terraform_backend_region
#
# and derives the state key as:
#   ire/<environment>/persistent/terraform.tfstate
#
# Those values are passed to `terraform init` from
# playbooks/terraform/common/deploy.yml or destroy.yml.
################################################################################

terraform {
  backend "s3" {}
}
