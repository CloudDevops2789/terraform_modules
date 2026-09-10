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
  - user001
  - user002
  - user003

managed_ad_bootstrap_secret_prefix: ire/sandbox/ad-users

managed_ad_bootstrap_reset_existing_passwords: false
```

## Idempotent Behavior

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


## Workflow Output

The AAP entry point publishes the Managed AD authorization-group SID after a
successful bootstrap:

```yaml
managed_ad_group_sid: S-1-5-21-...
```

This value is an operational identifier, not a credential. A downstream Remote
Access workflow consumes it as the Terraform `client_vpn_access_group_id`
binding.

The directory ID is supplied by the upstream Identity workflow. The bootstrap
role does not read Terraform state directly.

## Credential Handling

Each newly created user receives a unique generated bootstrap password.

Credential handling is performed through the boto3-backed
`managed_ad_user_credential` module:

```text
AWS Secrets Manager password generation
        |
        v
individual Secrets Manager record
        |
        v
AWS Managed Microsoft AD password
```

The password is not supplied through Git, Terraform variables, AAP Extra Vars,
shell arguments, or normal job output.

Normal idempotent execution preserves existing passwords. Password rotation for
an existing account occurs only when
`managed_ad_bootstrap_reset_existing_passwords` is explicitly enabled.
