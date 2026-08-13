##################################################################################################
# IAM Roles
##################################################################################################

locals {
  roles = {
    for role_key, role in var.roles :
    role_key => merge(
      role,
      {
        name = coalesce(role.name, role_key)
        tags = merge(var.tags, role.tags)
      }
    )
  }

  managed_policy_attachments = {
    for attachment in flatten([
      for role_key, role in local.roles : [
        for policy_arn in role.managed_policy_arns : {
          key        = "${role_key}:${sha1(policy_arn)}"
          role_key   = role_key
          policy_arn = policy_arn
        }
      ]
    ]) :
    attachment.key => attachment
  }

  inline_policies = {
    for policy in flatten([
      for role_key, role in local.roles : [
        for policy_name, policy_document in role.inline_policies : {
          key             = "${role_key}:${policy_name}"
          role_key        = role_key
          policy_name     = policy_name
          policy_document = policy_document
        }
      ]
    ]) :
    policy.key => policy
  }

  instance_profiles = {
    for role_key, role in local.roles :
    role_key => role
    if role.create_instance_profile
  }
}

resource "aws_iam_role" "this" {
  for_each = local.roles

  name                  = each.value.name
  description           = each.value.description
  path                  = each.value.path
  assume_role_policy    = each.value.assume_role_policy
  permissions_boundary  = each.value.permissions_boundary
  max_session_duration  = each.value.max_session_duration
  force_detach_policies = each.value.force_detach_policies

  tags = each.value.tags
}

##################################################################################################
# Managed Policy Attachments
##################################################################################################

resource "aws_iam_role_policy_attachment" "this" {
  for_each = local.managed_policy_attachments

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = each.value.policy_arn
}

##################################################################################################
# Inline Policies
##################################################################################################

resource "aws_iam_role_policy" "this" {
  for_each = local.inline_policies

  name   = each.value.policy_name
  role   = aws_iam_role.this[each.value.role_key].name
  policy = each.value.policy_document
}

##################################################################################################
# EC2 Instance Profiles
##################################################################################################

resource "aws_iam_instance_profile" "this" {
  for_each = local.instance_profiles

  name = coalesce(each.value.instance_profile_name, each.value.name)
  path = each.value.path
  role = aws_iam_role.this[each.key].name
  tags = each.value.tags
}
