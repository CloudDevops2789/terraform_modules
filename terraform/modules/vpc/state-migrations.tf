##################################################################################################
# Terraform State Migrations
##################################################################################################
#
# This file will contain moved blocks that preserve existing AWS resources
# when consumers migrate from the previous VPC interface.
#
# Migration mappings will be added after the existing environment roots have
# standardized their subnet and route-table keys.
#
# Do not add speculative moved blocks. Every source and destination address
# must correspond to a reviewed migration path.
