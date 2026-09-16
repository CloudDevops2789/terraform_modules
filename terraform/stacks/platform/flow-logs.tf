##################################################################################################
# Platform Network Flow Logging
##################################################################################################
#
# Ownership
# ---------
# Platform owns:
#
#   - all IRE VPCs;
#   - the IRE Transit Gateway;
#   - their associated network-flow telemetry.
#
# This file intentionally keeps Flow Logs outside the reusable VPC module.
# Flow logging introduces CloudWatch Logs and IAM delivery dependencies that
# are orchestration/observability concerns rather than VPC topology concerns.
#
# Current Sandbox policy
# ----------------------
#
#   destination              = CloudWatch Logs
#   VPC traffic type         = ALL
#   aggregation interval     = 60 seconds
#   retention                = environment controlled
#
# Transit Gateway Flow Logs do not use the VPC traffic_type setting.
# The 60-second aggregation interval is used for both telemetry scopes.
##################################################################################################

data "aws_caller_identity" "network_flow_logs" {}

data "aws_partition" "network_flow_logs" {}

##################################################################################################
# Effective Flow Log Targets
##################################################################################################

locals {
  network_flow_logs_enabled = (
    var.network_flow_logs.enabled &&
    (
      var.network_flow_logs.vpc_flow_logs_enabled ||
      var.network_flow_logs.transit_gateway_logs_enabled
    )
  )

  network_flow_log_vpcs = (
    var.network_flow_logs.enabled &&
    var.network_flow_logs.vpc_flow_logs_enabled
    ? module.vpc
    : {}
  )

  transit_gateway_flow_logs_enabled = (
    var.network_flow_logs.enabled &&
    var.network_flow_logs.transit_gateway_logs_enabled
  )

  network_flow_log_group_names = merge(
    {
      for vpc_key, vpc in local.network_flow_log_vpcs :
      "vpc-${vpc_key}" => "/aws/vpc/flow-logs/${local.name_prefix}/${replace(vpc_key, "_", "-")}"
    },
    local.transit_gateway_flow_logs_enabled
    ? {
      transit-gateway = "/aws/transit-gateway/flow-logs/${local.name_prefix}"
    }
    : {}
  )
}

##################################################################################################
# CloudWatch Log Groups
##################################################################################################

resource "aws_cloudwatch_log_group" "network_flow_logs" {
  for_each = local.network_flow_log_group_names

  name              = each.value
  retention_in_days = var.network_flow_logs.retention_in_days

  tags = merge(
    local.org_tags,
    {
      Name             = each.value
      org_service_name = "network-flow-logging"
      org_log_type     = each.key
    }
  )
}

##################################################################################################
# Flow Logs Delivery Role
##################################################################################################
#
# AWS VPC Flow Logs and Transit Gateway Flow Logs use the same service
# principal when delivering records to CloudWatch Logs.
#
# SourceAccount and SourceArn conditions reduce confused-deputy exposure.
##################################################################################################

data "aws_iam_policy_document" "network_flow_logs_assume_role" {
  count = local.network_flow_logs_enabled ? 1 : 0

  statement {
    sid     = "AllowVpcFlowLogsService"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"

      values = [
        data.aws_caller_identity.network_flow_logs.account_id
      ]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"

      values = [
        "arn:${data.aws_partition.network_flow_logs.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.network_flow_logs.account_id}:vpc-flow-log/*"
      ]
    }
  }
}

resource "aws_iam_role" "network_flow_logs" {
  count = local.network_flow_logs_enabled ? 1 : 0

  name = "${local.name_prefix}-network-flow-logs"

  description = "Allows AWS VPC and Transit Gateway Flow Logs to publish IRE network telemetry to CloudWatch Logs."

  assume_role_policy = (
    data.aws_iam_policy_document
    .network_flow_logs_assume_role[0]
    .json
  )

  tags = merge(
    local.org_tags,
    {
      Name             = "${local.name_prefix}-network-flow-logs"
      org_service_name = "network-flow-logging"
    }
  )
}

##################################################################################################
# CloudWatch Delivery Permissions
##################################################################################################

data "aws_iam_policy_document" "network_flow_logs_cloudwatch" {
  count = local.network_flow_logs_enabled ? 1 : 0

  statement {
    sid    = "WriteNetworkFlowLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]

    resources = [
      for log_group in values(aws_cloudwatch_log_group.network_flow_logs) :
      "${log_group.arn}:*"
    ]
  }

  statement {
    sid    = "DescribeCloudWatchLogGroups"
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "network_flow_logs_cloudwatch" {
  count = local.network_flow_logs_enabled ? 1 : 0

  name = "${local.name_prefix}-network-flow-logs-cloudwatch"

  role = aws_iam_role.network_flow_logs[0].id

  policy = (
    data.aws_iam_policy_document
    .network_flow_logs_cloudwatch[0]
    .json
  )
}

##################################################################################################
# VPC Flow Logs
##################################################################################################
#
# The loop automatically follows Platform's VPC map. Adding a new VPC to
# network_config does not require another hardcoded Flow Log resource.
##################################################################################################

resource "aws_flow_log" "vpc" {
  for_each = local.network_flow_log_vpcs

  vpc_id = each.value.vpc_id

  traffic_type             = "ALL"
  max_aggregation_interval = 60

  log_destination_type = "cloud-watch-logs"

  log_destination = (
    aws_cloudwatch_log_group
    .network_flow_logs["vpc-${each.key}"]
    .arn
  )

  iam_role_arn = aws_iam_role.network_flow_logs[0].arn

  tags = merge(
    local.org_tags,
    {
      Name             = "${local.name_prefix}-${replace(each.key, "_", "-")}-flow-log"
      org_service_name = "vpc-flow-logging"
      org_vpc_key      = each.key
    }
  )

  depends_on = [
    aws_iam_role_policy.network_flow_logs_cloudwatch
  ]
}

##################################################################################################
# Transit Gateway Flow Log
##################################################################################################
#
# Transit Gateway Flow Logs complement VPC Flow Logs. They record traffic
# observed at the TGW rather than traffic at individual VPC network interfaces.
##################################################################################################

resource "aws_flow_log" "transit_gateway" {
  count = local.transit_gateway_flow_logs_enabled ? 1 : 0

  transit_gateway_id = module.transit_gateway.id

  max_aggregation_interval = 60

  log_destination_type = "cloud-watch-logs"

  log_destination = (
    aws_cloudwatch_log_group
    .network_flow_logs["transit-gateway"]
    .arn
  )

  iam_role_arn = aws_iam_role.network_flow_logs[0].arn

  tags = merge(
    local.org_tags,
    {
      Name             = "${local.name_prefix}-transit-gateway-flow-log"
      org_service_name = "transit-gateway-flow-logging"
    }
  )

  depends_on = [
    aws_iam_role_policy.network_flow_logs_cloudwatch
  ]
}
