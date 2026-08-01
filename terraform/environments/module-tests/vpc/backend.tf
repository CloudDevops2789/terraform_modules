# REMOTE STATE configuration. Each module test gets its own state key so
# that applying/destroying one test can never affect another test's
# resources or lock file.
terraform {

  backend "s3" {

    bucket = "yoganand-terraform-state-781436988948"

    key = "module-tests/vpc/terraform.tfstate"

    region = "us-east-1"

    use_lockfile = true

    encrypt = true

  }

}
