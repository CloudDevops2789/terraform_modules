##################################################################################################
# CloudWatch Logs Destinations
##################################################################################################
# Destination lifecycle remains outside the reusable logging module. Short retention limits the cost
# of this apply test while still proving real AWS log-delivery configuration.
resource "aws_cloudwatch_log_group" "alert" {
  name              = "/aws/network-firewall/module-test/alert"
  retention_in_days = 1
  tags              = local.org_tags
}
resource "aws_cloudwatch_log_group" "flow" {
  name              = "/aws/network-firewall/module-test/flow"
  retention_in_days = 1
  tags              = local.org_tags
}
