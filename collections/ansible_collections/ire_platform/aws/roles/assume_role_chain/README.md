# Assume Role Chain

Assumes a base AWS role and then, when `target_role_arn` is supplied, assumes the target deployment role using the first role's temporary credentials.

The role validates both account IDs when the corresponding guards are supplied. It publishes the final credentials as `aws_auth` and `assume_role_aws_auth`; credential values are never logged.

Required role-chain inputs:

- `role_arn`
- `target_role_arn`
- `aws_region`
- `role_expected_account_id`
- `target_role_expected_account_id`

The final facts are compatible with both the source role contract (`aws_access_key_id`, `aws_secret_access_key`, `aws_session_token`, `aws_auth`) and this repository's Terraform lifecycle (`assume_role_aws_auth`).
