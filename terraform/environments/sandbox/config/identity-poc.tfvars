################################################################################
# Managed AD Functional PoC
#
# Existing VPC and subnet IDs are supplied at AAP runtime and are deliberately
# not committed here.
################################################################################

domain_name = "poc.ad.ire.ransprot.com"
short_name  = "IREPOC"
edition     = "Standard"

tags = {
  purpose    = "managed-ad-bootstrap-poc"
  managed_by = "terraform"
}
