# Module Tests

This directory is a collection of independent Terraform root modules, one
per folder, each answering exactly one question: **can this module deploy
successfully?** It is the entry point for anyone new to this repository who
wants to understand or validate an individual module in
`terraform/modules/` without needing to reason about the full sandbox
topology.

## Why module-tests exists

`terraform/modules/` contains the reusable building blocks this repository
is built from - vpc, transit-gateway, ec2, security-group, client-vpn,
kms, the backup modules, managed-microsoft-ad, and others. Before any of
those blocks are trusted inside `sandbox` (or, eventually, a production
environment), each one needs to be provably deployable on its own: does
it accept its documented inputs, does it create the resources its README
says it creates, does `terraform apply` succeed and `terraform destroy`
clean up completely?

Answering that inside `sandbox` is awkward. Sandbox composes many modules
into one interconnected topology - a change or a bug anywhere in that
topology can make it hard to tell which module actually failed, and
tearing down or rebuilding sandbox just to check one module is slow and
disruptive. `module-tests` exists to isolate that question: one module
(or one tightly-coupled pair of modules, see below) per Terraform root,
with nothing else in the way.

## Difference between sandbox and module-tests

`sandbox` is an **integration environment**. It composes many modules
together into a real (if small) Isolated Recovery Environment topology -
three VPCs, a Transit Gateway routing between them, Client VPN access,
backup infrastructure, and so on - because the point of sandbox is to
prove those modules work correctly *together*, wired the way a real
deployment would wire them.

`module-tests` is a **unit test environment**. Each folder deploys one
module (or one inseparable pair) plus the absolute minimum supporting
infrastructure that module needs to exist at all. It does not attempt to
reproduce sandbox's topology, trust model, or routing - that composition
is sandbox's job, not this directory's. If sandbox breaks, the module
tests are where you'd check whether the fault lies in an individual
module or in how sandbox wires modules together.

## Design philosophy

- **Test one thing.** Each folder validates one module's ability to
  deploy. Supporting resources exist only because the module under test
  cannot be created without them - never because they seemed useful to
  include.
- **Minimum footprint.** If a module needs a VPC to attach to, this
  directory creates the smallest VPC that satisfies that requirement (one
  subnet, not three; no Internet Gateway unless required), not a
  realistic network design.
- **Self-contained by default.** Every test can run start-to-finish with
  a single `terraform apply` and be torn down with a single
  `terraform destroy`, with no manual prerequisite steps. Where a module
  needs something that can't reasonably be faked (like an AWS Managed
  Microsoft AD password), that becomes a required variable instead -
  never a hardcoded secret.
- **Documented reasoning, not documented syntax.** Comments throughout
  this directory explain *why* a resource exists, not *what* Terraform
  API call it makes. `# Creates a subnet.` is not useful; `# The Client
  VPN endpoint requires private subnets for endpoint associations - this
  VPC exists solely to satisfy that.` is.

## Folder layout

```
module-tests/
├── README.md                    <- this file
├── vpc/                         <- terraform/modules/vpc
├── transit-gateway/              <- terraform/modules/transit-gateway
├── ec2/                          <- terraform/modules/ec2
├── security-group/               <- terraform/modules/security-group + security-group-rule
├── client-vpn/                   <- terraform/modules/client-vpn
├── kms/                          <- terraform/modules/kms
├── backup-vault/                 <- terraform/modules/backup-standard-vault,
│                                     backup-logically-air-gapped-vault, backup-role,
│                                     backup-plan, backup-selection
└── managed-microsoft-ad/         <- terraform/modules/managed-microsoft-ad
```

Two folders test more than one library module each, and each one explains
why in its own README:

- `security-group/` tests `security-group` and `security-group-rule`
  together, because a rule cannot exist without a group to attach to -
  they are never deployed independently, in sandbox or anywhere else.
- `backup-vault/` tests all five AWS Backup modules together
  (`backup-standard-vault`, `backup-logically-air-gapped-vault`,
  `backup-role`, `backup-plan`, `backup-selection`), because a plan needs
  a vault, a role, and a selection to be useful, and sandbox deploys them
  the same way.

Every folder follows the same internal shape:

```
<name>/
├── backend.tf                   <- S3 state, unique key per test
├── provider.tf                  <- AWS provider (+ tls provider where needed)
├── versions.tf                  <- Terraform/provider version constraints
├── variables.tf                 <- inputs, heavily commented (see below)
├── locals.tf                    <- static configuration, organized by domain
├── *.tf                         <- resources, organized by purpose
│                                    (networking.tf, security.tf, compute.tf, ...)
├── outputs.tf                   <- proof the module under test actually deployed
├── terraform.tfvars.example     <- copy to terraform.tfvars and adjust
└── README.md                    <- Purpose / Module Under Test / Supporting
                                     Resources / Deployment / Destroy /
                                     Expected Outcome / Notes
```

Every `variables.tf` documents, for each variable: why it exists, whether
it's optional, whether it overrides a generated resource, and whether
this environment can produce a working default automatically when it's
left unset.

## How to execute a module test

Each folder is a complete, independent Terraform root:

```bash
cd module-tests/<name>
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars if the test has anything to configure -
# see that folder's own README.md and terraform.tfvars.example
terraform init
terraform plan
terraform apply
terraform destroy
```

That's the whole workflow - no bootstrap scripts, no ordering between
folders, no shared state to initialize first.

## Why every module test contains minimal supporting infrastructure

A module's `README.md` and `variables.tf` describe its interface, but the
only way to prove that interface actually works against real AWS APIs is
to give it real inputs and apply it. Most modules in this repository
depend on something they don't create themselves - the ec2 module needs a
subnet, the transit-gateway module needs a VPC to attach to, the
client-vpn module needs ACM certificate ARNs. Each module test creates
exactly the smallest set of resources that satisfies those dependencies
and nothing more, so that a passing `terraform apply` is unambiguous
evidence that the module under test works, not evidence that some larger
assembly of infrastructure happens to work.

## Why every module test is an independent Terraform root

Each folder has its own `backend.tf`, its own provider configuration, and
its own full set of resources - it does not `source` another root module
or read another root's outputs. This means:

- Any test can be applied or destroyed without needing any other test to
  exist, be up to date, or even be valid.
- A bug or a breaking change in one test cannot cascade into another.
- A new contributor can read and fully understand one folder without
  needing context from any other folder in this repository.

## Why supporting resources are intentionally not shared

It might seem more DRY to put the "minimal VPC" pattern that six of these
folders use into a shared module or a `common/` directory that every test
imports. This repository deliberately does not do that, for the same
reason each test is an independent root: sharing Terraform configuration
between roots introduces coupling. A change to a shared VPC definition
would now need to be evaluated against every test that depends on it,
turning "does the ec2 module deploy" into "does the ec2 module deploy
*and* does the shared networking module still work as this test expects."
That reintroduces the exact problem `module-tests` exists to avoid. The
small amount of duplication (each test's own `module.vpc` block) is a
deliberate trade for keeping every test provably independent.

## Why there is one Terraform state per module test

Every folder's `backend.tf` points at the same S3 bucket sandbox uses,
but with a unique state key
(`module-tests/<name>/terraform.tfstate`). One state per test means:

- Applying or destroying one test can never lock, corrupt, or otherwise
  affect another test's state.
- A test can be destroyed and re-applied repeatedly (which is the normal
  workflow for a module test, run far more often than sandbox is) without
  any risk to sandbox's own state or any other test's.
- There is never a question of which resources belong to which test -
  `terraform state list` inside any folder shows only that folder's
  resources.

## How these environments can later be adapted for enterprise deployments

Home lab defaults - throwaway self-signed certificates, cheap instance
types, short backup retention windows - keep these tests fast and free to
run repeatedly. Several are already built to accept real, existing AWS
resources instead of generating throwaway ones, without any change to the
module interfaces themselves:

- `client-vpn/` accepts `server_certificate_arn` and
  `root_certificate_chain_arn`. Left unset, it generates and imports a
  throwaway self-signed certificate chain. Supplied, it validates the
  module against certificates an enterprise already issues and manages
  through its own PKI.
- `managed-microsoft-ad/` requires `managed_ad_password` rather than
  generating one, since there is no safe way to auto-generate a directory
  credential - the same posture an enterprise deployment would take.

Variable names are deliberately aligned with `terraform/environments/sandbox`
(`managed_ad_password`, `server_certificate_arn`,
`root_certificate_chain_arn`) so the same values, or the same secrets
management approach, translate directly between a module test and
sandbox. Extending this pattern to other tests - for example, letting
`backup-vault/` accept an existing KMS key ARN instead of using the AWS
managed key - is a natural next step and would follow the same shape:
add an optional variable defaulting to `null`, and gate the generated
resource's `count` on whether it was supplied.
