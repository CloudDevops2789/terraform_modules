##################################################################################################
# AWS Provider
##################################################################################################
#
# The Region is supplied by the lifecycle environment. The Inspection stack
# intentionally owns no resources yet; provider configuration is established
# now so the root follows the same execution model as the other lifecycle
# stacks before Network Firewall ownership is transferred.
##################################################################################################

provider "aws" {
  region = var.aws_region
}
