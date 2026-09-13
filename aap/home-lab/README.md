# Home Lab AWX Configuration as Code

This directory manages the IRE lifecycle objects in the local/home-lab AWX instance.

It is not the source of truth for organizational AAP configuration. The organization uses its own AAP Configuration-as-Code repository.

## Managed AWX objects

The home-lab CaC manages:

- one dedicated SCM Project: `IRE Home Lab IaC`
- 23 Job Templates
- two Workflow Job Templates
- workflow approval and success-node relationships

The two lifecycle workflows are:

- `IRE-Sandbox-Full-Deploy`
- `IRE-Sandbox-Full-Destroy`

AWS Network Firewall / the Inspection Terraform stack is intentionally not included in these workflows.

## Controller authentication

Supply AWX connection credentials through shell environment variables:

    export CONTROLLER_HOST="http://172.22.216.253:31079"
    export CONTROLLER_USERNAME="<awx-username>"
    export CONTROLLER_PASSWORD="<awx-password>"
    export CONTROLLER_VERIFY_SSL="false"

Do not commit the AWX password.

## Collections

Install the required collection with:

    ansible-galaxy collection install -r aap/home-lab/requirements.yml

The current home-lab implementation uses `awx.awx` directly.

## Repository collection path

When running from a Windows-mounted WSL path, the repository ansible.cfg may be ignored because the directory is world writable.
Expose the repository collection explicitly when performing local validation:

    export ANSIBLE_COLLECTIONS_PATH="$PWD/collections:$HOME/.ansible/collections:/usr/share/ansible/collections"

## Environment-specific lifecycle inputs

Do not commit home-lab certificate identifiers or operational AD principals into the structural CaC.

Create an untracked file named `aap/home-lab/runtime.yml` from `runtime.example.yml` and provide:

- Managed AD authorization group name
- Managed AD bootstrap users
- Client VPN server ACM certificate ARN
- Client VPN client/root ACM certificate ARN

Run the CaC with:

    ansible-playbook aap/home-lab/configure.yml -e @aap/home-lab/runtime.yml

## Safety model

Standalone Terraform Destroy Job Templates are non-destructive by default.
The Full Destroy workflow injects the destroy-enable flag and exact confirmation only after the corresponding approval node.

Managed AD user and secret cleanup has its own explicit approval node before unbootstrap.

## Deployment order

    Persistent Plan -> Approval -> Persistent Apply
    Platform Plan   -> Approval -> Platform Apply
    Identity Plan   -> Approval -> Identity Apply
    Managed AD Bootstrap
    Remote Access Plan -> Approval -> Remote Access Apply
    Recovery Plan      -> Approval -> Recovery Apply

## Destruction order

    Recovery Destroy Plan -> Approval -> Recovery Destroy
    Remote Access Destroy Plan -> Approval -> Remote Access Destroy
    Identity Contract Read
    Managed AD Cleanup Approval -> Managed AD Unbootstrap
    Identity Destroy Plan -> Approval -> Identity Destroy
    Platform Destroy Plan -> Approval -> Platform Destroy
    Persistent Destroy Plan -> Approval -> Persistent Destroy
