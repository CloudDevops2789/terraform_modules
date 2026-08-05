##################################################################################################
# Terraform State Migrations
##################################################################################################
#
# This file preserves resource identity when internal Terraform addresses
# change between module versions.
#
# Moved blocks do not create AWS resources. They tell Terraform that an
# existing resource has a new configuration address, preventing unnecessary
# destruction and recreation during module upgrades.
#
# Do not remove a moved block until every supported consumer has upgraded
# beyond the module version that introduced the migration.

moved {
  from = aws_route_table.private
  to   = aws_route_table.legacy_private["legacy"]
}