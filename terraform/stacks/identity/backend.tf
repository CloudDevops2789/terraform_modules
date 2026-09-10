################################################################################
# Terraform Backend
#
# Backend values are intentionally not hardcoded in this root.
#
# AAP supplies:
#   terraform_backend_bucket
#   terraform_backend_region
#
# and derives the Identity state key as:
#
#   ire/<environment>/identity/terraform.tfstate
#
# Backend initialization is performed by the shared Terraform lifecycle engine
# under playbooks/terraform/common/.
################################################################################

terraform {
  backend "s3" {}
}
