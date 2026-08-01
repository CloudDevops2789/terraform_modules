locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  default_tags = {
    TestedModule = "kms"
  }

  ##################################################################################################
  # KMS Under Test
  ##################################################################################################
  # The kms module is fully self-contained: it resolves the calling AWS
  # identity itself (bootstrap_current_caller defaults to true) rather than
  # requiring the caller to supply administrator ARNs, so no supporting
  # resources are needed to validate that it deploys.
  kms = {
    description = "Module test - customer managed KMS key"
    alias       = "module-test-kms"
  }
}
