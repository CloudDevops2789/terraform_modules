# Managed AD Unbootstrap Role

`ire_platform.aws.managed_ad_unbootstrap` provides the operational cleanup
lifecycle for users previously managed by the Managed AD bootstrap workflow.

The role is intentionally separate from `managed_ad_bootstrap` so destructive
identity operations cannot occur through the ordinary provisioning path.

## Responsibilities

The role can perform two lifecycle operations.

### Revoke access only

Removes selected users from the Managed AD authorization group while retaining:

- the directory user
- the user's Managed AD password
- the corresponding AWS Secrets Manager secret

This is the default and preferred operation when a user temporarily or
permanently no longer requires IRE access but their directory identity should
remain available.

Required confirmation:

```yaml
managed_ad_unbootstrap_confirmation: REVOKE MANAGED AD ACCESS
```

### Full deprovision

Removes selected users from the authorization group and additionally:

- deletes the Managed AD user
- schedules the corresponding Secrets Manager secret for deletion

Required confirmation:

```yaml
managed_ad_unbootstrap_confirmation: REMOVE MANAGED AD USERS
```

Secret deletion uses an AWS Secrets Manager recovery window. Immediate
force deletion is intentionally unsupported.

## Ownership

Lifecycle ownership is:

```text
Terraform
  -> Managed AD infrastructure

managed_ad_bootstrap
  -> bootstrap group
  -> directory users
  -> group memberships
  -> bootstrap credentials

managed_ad_unbootstrap
  -> membership revocation
  -> optional directory-user deletion
  -> optional bootstrap-secret deletion scheduling
```

The authorization group itself is not deleted by this role.

## Inputs

```yaml
managed_ad_unbootstrap_directory_id: d-xxxxxxxxxx
managed_ad_unbootstrap_region: us-east-1

managed_ad_unbootstrap_group_name: IRE_ClientVPN_Users

managed_ad_unbootstrap_users:
  - user01
  - user02

managed_ad_unbootstrap_secret_prefix: ire/sandbox/ad-users

managed_ad_unbootstrap_delete_users: false
managed_ad_unbootstrap_delete_secrets: false

managed_ad_unbootstrap_secret_recovery_days: 7

managed_ad_unbootstrap_confirmation: REVOKE MANAGED AD ACCESS
```

The AAP entry-point playbook derives the directory ID, Region and secret prefix
from the workflow/environment contract. Operators should normally provide only
the requested users, lifecycle flags and confirmation value.

## Revoke Access Example

```yaml
managed_ad_unbootstrap_group_name: IRE_ClientVPN_Users

managed_ad_unbootstrap_users:
  - user01

managed_ad_unbootstrap_delete_users: false
managed_ad_unbootstrap_delete_secrets: false

managed_ad_unbootstrap_confirmation: REVOKE MANAGED AD ACCESS
```

Result:

```text
group membership removed
directory user retained
Secrets Manager secret retained
```

## Full Deprovision Example

```yaml
managed_ad_unbootstrap_group_name: IRE_ClientVPN_Users

managed_ad_unbootstrap_users:
  - user01

managed_ad_unbootstrap_delete_users: true
managed_ad_unbootstrap_delete_secrets: true
managed_ad_unbootstrap_secret_recovery_days: 7

managed_ad_unbootstrap_confirmation: REMOVE MANAGED AD USERS
```

Result:

```text
group membership removed
directory user deleted
Secrets Manager secret scheduled for deletion
```

## Safety Controls

The role enforces the following guardrails:

- an explicit non-empty user list is required
- duplicate usernames are rejected
- usernames must satisfy the Managed AD SAM account-name validation
- secret deletion cannot be enabled unless directory-user deletion is enabled
- access revocation requires the exact `REVOKE MANAGED AD ACCESS` confirmation
- user deletion requires the exact `REMOVE MANAGED AD USERS` confirmation
- secret deletion requires a recovery window from 7 through 30 days
- immediate Secrets Manager force deletion is not supported
- the Managed AD authorization group is never deleted

## Idempotency

Already-cleaned resources do not cause a failure.

The lifecycle safely handles:

```text
group already absent
membership already absent
user already absent
secret already absent
secret already scheduled for deletion
```

Re-running the same completed cleanup request therefore results in no additional
destructive change.

## Secret Naming

The AAP entry point derives the same deterministic secret prefix used by the
bootstrap workflow:

```text
ire/<environment>/ad-users/<username>
```

Operators do not provide secret ARNs or manually map users to secrets.

## AWS Authentication

The role uses the normal boto3 AWS credential chain provided by its caller.

It does not:

- assume IAM roles itself
- contain AAP credential logic
- contain passwords
- return secret values
- perform shell-based AWS operations
