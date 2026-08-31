output "endpoint_id" {
  description = "Route 53 Resolver endpoint ID."
  value       = aws_route53_resolver_endpoint.this.id
}

output "endpoint_arn" {
  description = "Route 53 Resolver endpoint ARN."
  value       = aws_route53_resolver_endpoint.this.arn
}

output "host_vpc_id" {
  description = "VPC that contains the Resolver endpoint ENIs."
  value       = aws_route53_resolver_endpoint.this.host_vpc_id
}

output "resolver_rule_ids" {
  description = "Resolver rule IDs keyed by caller-defined rule key."
  value = {
    for rule_key, rule in aws_route53_resolver_rule.this :
    rule_key => rule.id
  }
}

output "rule_association_ids" {
  description = "Resolver rule-association IDs keyed by rule and VPC identity."
  value = {
    for association_key, association in aws_route53_resolver_rule_association.this :
    association_key => association.id
  }
}

output "query_log_association_ids" {
  description = "Resolver query-log association IDs keyed by caller-defined VPC key."
  value = {
    for vpc_key, association in aws_route53_resolver_query_log_config_association.this :
    vpc_key => association.id
  }
}
