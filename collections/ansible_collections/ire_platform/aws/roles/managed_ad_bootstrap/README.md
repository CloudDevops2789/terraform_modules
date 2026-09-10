# Managed AD Bootstrap Role

## Purpose

`ire_platform.aws.managed_ad_bootstrap` manages directory-level bootstrap
objects after AWS Managed Microsoft AD infrastructure exists.

Terraform continues to own the directory infrastructure. This role owns
operational directory bootstrap activities such as:

- creating approved directory groups;
- creating approved users;
- generating unique bootstrap passwords;
- adding users to groups;
- storing credentials in AWS Secrets Manager;
- retrieving the group SID required by downstream services such as AWS Client
  VPN.

## Ownership Boundary

```text
Terraform Identity stack
        |
        | identity_contract.directory_id
        v
Managed AD Bootstrap role
        |
        +-- users
        +-- groups
        +-- memberships
        +-- bootstrap credentials
        +-- Secrets Manager records
        |
        v
Remote Access
```

Passwords must never be stored in Git, Terraform state, AAP Extra Vars, normal
AAP job output, or repository configuration.

## Inputs

```yaml
managed_ad_bootstrap_directory_id: d-xxxxxxxxxx
managed_ad_bootstrap_region: us-east-1

managed_ad_bootstrap_group_name: IRE_ClientVPN_Users

managed_ad_bootstrap_users:
  - yog73018
  - yog73019
  - yog73020

managed_ad_bootstrap_secret_prefix: ire/sandbox/ad-users

managed_ad_bootstrap_reset_existing_passwords: false
```

## Planned Idempotent Behavior

```text
New user
  -> create user
  -> generate unique password
  -> store credential in Secrets Manager
  -> set password
  -> add group membership

Existing user
  -> preserve password
  -> preserve existing secret
  -> ensure group membership

Explicit password reset
  -> generate new unique password
  -> reset directory password
  -> update the corresponding Secrets Manager secret
```

The role must use `no_log: true` for every task that handles plaintext
credentials.
