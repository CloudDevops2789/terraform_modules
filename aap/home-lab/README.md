# Home Lab AWX Configuration as Code

This directory manages the IRE lifecycle objects in the local/home-lab AWX
instance.

It is not the source of truth for organizational AAP configuration. The
organization uses its own AAP Configuration-as-Code repository.

## Scope

The home-lab CaC manages:

- one dedicated SCM Project: `IRE Home Lab IaC`
- 38 Job Templates
- two Workflow Job Templates
- workflow node relationships
- removal of obsolete approval nodes from the earlier gated test model

The lifecycle workflows are:

- `IRE-Sandbox-Full-Deploy`
- `IRE-Sandbox-Full-Destroy`


## Controller authentication

Supply AWX connection information through shell environment variables:

    export CONTROLLER_HOST="http://172.22.216.253:31079"
    export CONTROLLER_OAUTH_TOKEN="<awx-token>"
    export CONTROLLER_VERIFY_SSL="false"

Do not commit the AWX token.

## Collections

Install the required collection with:

    ansible-galaxy collection install -r aap/home-lab/requirements.yml

The home-lab implementation uses `awx.awx` directly.

## Repository collection path

When running from a Windows-mounted WSL path, the repository `ansible.cfg` may
be ignored because the directory is world writable.

Expose the repository collection explicitly during local validation:

    export ANSIBLE_COLLECTIONS_PATH="$PWD/collections:$HOME/.ansible/collections:/usr/share/ansible/collections"

## Runtime lifecycle inputs

Environment-specific lifecycle values are stored outside Git.

Copy:

    aap/home-lab/runtime.example.yml

to:

    aap/home-lab/runtime.yml

The runtime file supplies:

- Managed AD authorization group
- Managed AD bootstrap users
- Client VPN client/root ACM certificate ARN

`runtime.yml` is ignored by Git.

Apply the CaC with:

    ansible-playbook \
      aap/home-lab/configure.yml \
      -e @aap/home-lab/runtime.yml

Running the CaC configures AWX objects only. It does not launch either
lifecycle workflow.

## Complete deployment workflow

The complete home-lab deployment test runs without approval nodes:

    Persistent Plan
    -> Persistent Apply
    -> Platform Plan
    -> Platform Apply
    -> Inspection Plan
    -> Inspection Apply
    -> Identity Plan
    -> Identity Apply
    -> Managed AD Bootstrap
    -> Client VPN Certificate Provision
    -> Remote Access Plan
    -> Remote Access Apply
    -> Recovery Plan
    -> Recovery Apply

Each Terraform Plan therefore runs immediately before its corresponding Apply.

## Complete destruction workflow

The complete destruction workflow runs in reverse dependency order:

    Recovery Destroy Plan
    -> Recovery Destroy
    -> Remote Access Destroy Plan
    -> Remote Access Destroy
    -> Identity Contract Read
    -> Managed AD Unbootstrap
    -> Identity Destroy Plan
    -> Identity Destroy
    -> Inspection Destroy Plan
    -> Inspection Destroy
    -> Platform Destroy Plan
    -> Platform Destroy
    -> Persistent Destroy Plan
    -> Persistent Destroy

Launching `IRE-Sandbox-Full-Destroy` is intentionally destructive.

## Destroy safety model

The individual Terraform Destroy Job Templates remain non-destructive by
default:

    terraform_destroy_enabled: false
    terraform_destroy_confirmation: ""

The Full Destroy workflow injects the destructive enable flag and exact
confirmation string into the actual destroy nodes.

This means a normal direct launch of an individual Destroy Job Template produces
a destroy plan but does not apply the destruction unless the required
authorization variables are deliberately supplied.

Managed AD unbootstrap during the complete destroy test removes the configured
bootstrap users and schedules their bootstrap secrets for deletion using the
configured recovery window.

## Identity contract handling

Identity Apply publishes the Managed AD directory contract for downstream jobs
during deployment.

A separate read-only `IRE-Identity-Contract-Read` Job Template resolves the
existing Identity Terraform output at the start of the identity-cleanup portion
of a separately launched destroy workflow.

The reader does not modify Terraform state or AWS infrastructure.
