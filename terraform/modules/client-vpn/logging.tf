############################################
# CloudWatch Log Group
############################################

# Stores Client VPN connection logs.
#
# These logs capture connection attempts, authentication events,
# session establishment and disconnects.
#
# The log group is created inside the module because it is tightly
# coupled to the Client VPN endpoint.
resource "aws_cloudwatch_log_group" "this" {

  name = "/aws/client-vpn/${var.name}"

  retention_in_days = var.log_retention_in_days

  tags = local.default_tags
}

############################################
# CloudWatch Log Stream
############################################

# Log stream where the Client VPN endpoint writes its
# connection events.
resource "aws_cloudwatch_log_stream" "this" {

  name = "connections"

  log_group_name = aws_cloudwatch_log_group.this.name
}