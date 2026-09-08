##################################################################################################
# Inspection Lifecycle Composition
##################################################################################################
#
# This root intentionally contains no AWS resources yet.
#
# The stack boundary is established before resource ownership is transferred
# from Platform so the new backend, dependency contract, AAP entry points and
# lifecycle controls can be validated independently.
#
# Future ownership:
#
#   - AWS Network Firewall
#   - Network Firewall rule groups
#   - Network Firewall policy
#   - CloudWatch log groups and firewall logging
#   - routes whose next hop depends on Network Firewall endpoint IDs
#
# Platform continues to own the Inspection VPC, subnets, Transit Gateway,
# VPC attachments and base topology.
##################################################################################################
