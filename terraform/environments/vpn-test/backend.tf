# REMOTE STATE configuration. By default Terraform stores state in a local
# terraform.tfstate file; this block moves it to S3 so state survives laptop
# loss and can be shared/locked between users and CI.
# Backend config is read at `terraform init` time (not plan/apply) and cannot
# use variables - values must be literals here or passed via -backend-config.
terraform {

  # encrypt=true -> server-side encryption of the state object (state contains
  # resource attributes and can contain secrets, so this matters).
  # use_lockfile=true -> native S3 state locking (Terraform >= 1.10), which
  # replaces the old DynamoDB lock table approach.
  backend "s3" {

    bucket = "yoganand-terraform-state-781436988948"

    key = "sandbox/networking/terraform.tfstate"

    region = "us-east-1"

    use_lockfile = true

    encrypt = true

  }

}
