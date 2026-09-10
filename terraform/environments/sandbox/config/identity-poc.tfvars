################################################################################
# Managed AD Functional PoC
#
# Existing VPC and subnet IDs are supplied at AAP runtime and are deliberately
# not committed here.
################################################################################

domain_name = "ad.fairview-ire.org"
short_name  = "FVIRE"
edition     = "Standard"

tags = {
  purpose    = "managed-ad-bootstrap-poc"
  managed_by = "terraform"
}
