# Purpose

Validates that the `ec2` module (`terraform/modules/ec2`) deploys
successfully: one instance created via the module's `for_each` over
`var.instances`.

# Module Under Test

`terraform/modules/ec2`

This test exercises instance creation, the module's tag-merging locals,
its `key_name` attribute against a real key pair, and its handling of
unset optional attributes (`iam_instance_profile`, `private_ip`,
`root_block_device`), which resolve to their documented defaults.

# Supporting Resources

- `module.vpc` (`networking.tf`) - `aws_instance` requires a real
  `subnet_id` to launch into; the ec2 module does not create networking
  itself. One private subnet is the minimum shape needed. Not under test.
- `module.security_group` (`security.tf`) - `aws_instance` requires a real
  security group ID. No explicit rules are configured because AWS attaches
  its own default allow-all egress rule automatically, and rule behavior
  is validated by the `security-group/` module test, not here. Not under
  test. No inbound rule permits SSH, so the key pair below proves
  `key_name` wiring rather than actual reachability.
- `module.key_pair` (`compute.tf`) - the ec2 module accepts an optional
  `key_name`; this key pair exists so that attribute is exercised against
  a real AWS key pair instead of being left unset, the same way sandbox
  uses `terraform/modules/key-pair` for the same reason. Not under test.

# Deployment

Example Private Only VPCs
```
module "vpc" {

  source = "../../modules/vpc"

  vpc_name   = "private-vpc"
  cidr_block = "10.100.0.0/16"

  availability_zone_count = 2

  private_subnets = {
    private-a = "10.100.11.0/24"
  }

}

VPC
└── AZ-1
    └── private-a
```
Example 2 — Two AZ Private VPC (Recommended)
```
module "vpc" {

  source = "../../modules/vpc"

  vpc_name   = "private-vpc"
  cidr_block = "10.100.0.0/16"

  availability_zone_count = 2

  private_subnets = {

    private-a = "10.100.11.0/24"

    private-b = "10.100.12.0/24"

  }

}

                 VPC
          ┌───────────────┐
          │               │
        AZ-1           AZ-2
          │               │
    private-a       private-b
```

Example 3 — Public + Private
```
module "vpc" {

  source = "../../modules/vpc"

  vpc_name   = "web-vpc"
  cidr_block = "10.100.0.0/16"

  availability_zone_count = 2

  public_subnets = {

    public-a = "10.100.1.0/24"

    public-b = "10.100.2.0/24"

  }

  private_subnets = {

    private-a = "10.100.11.0/24"

    private-b = "10.100.12.0/24"

  }

}

                      VPC

         AZ-1                     AZ-2

   public-a                 public-b

   private-a                private-b

        │                        │
        └──── Internet Gateway ──┘

```
Example 4 — Three AZ Deployment

availability_zone_count = 3

public_subnets = {

  public-a = "10.100.1.0/24"

  public-b = "10.100.2.0/24"

  public-c = "10.100.3.0/24"

}

private_subnets = {

  private-a = "10.100.11.0/24"

  private-b = "10.100.12.0/24"

  private-c = "10.100.13.0/24"

}

                  VPC

     AZ-1        AZ-2        AZ-3

   public-a    public-b    public-c

   private-a   private-b   private-c

```

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars and set public_key_path to a real SSH public key
terraform init
terraform plan
terraform apply
```

# Destroy

```bash
terraform destroy
```

Nothing in this environment has a retention/lock that would block
destroy - a plain `terraform destroy` removes the instance, the key pair,
the security group, and the supporting VPC together.

# Expected Outcome

`terraform apply` completes with no errors and reports one VPC, one
subnet, one security group, one key pair, and one EC2 instance with
`key_name` set. `instance_ids` and `private_ips` are populated outputs.

# Notes

The VPC, security group, and key pair in this environment exist only to
satisfy the EC2 module's dependencies on a real subnet, security group
ID, and key pair name. None of them are themselves under test - changes
to networking or security group behavior belong in the `vpc/` and
`security-group/` module tests.

`public_key_path` intentionally uses the same variable name as
`terraform/environments/sandbox`. It is required, not optional: unlike
the Client VPN test's certificates, there is no safe way to auto-generate
a real SSH key pair's public half as a static default.
