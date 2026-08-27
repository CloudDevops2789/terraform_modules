################################################################################
# Short-lived Client VPN + AWS Managed AD proof environment
################################################################################
#
# This standalone root deliberately avoids the four-VPC Platform stack. The
# neutral baseline uses a documentation-only domain; customer branches replace
# it with an approved non-production test domain before apply.

domain_name       = "poc.example.com"
directory_edition = "Standard"

vpc_cidr_block    = "10.250.0.0/16"
client_cidr_block = "172.27.240.0/22"

test_instance_type = "t3.micro"

# Runtime-only POC controls remain at their safe defaults:
# client_vpn_enabled = false
# authentication_type = "directory"
#
# AAP supplies public_key and the sensitive Managed AD password. After the
# directory bootstrap job returns a group SID, AAP supplies
# client_vpn_access_group_id when enabling the Client VPN stage.
