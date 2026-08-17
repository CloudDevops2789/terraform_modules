data "aws_partition" "current" {}

module "iam" {
  source = "../../../modules/iam"

  roles = {
    example_ec2_management = {
      name = "example-ire-ec2-management"

      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Service = "ec2.amazonaws.com"
            }
            Action = "sts:AssumeRole"
          }
        ]
      })

      managed_policy_arns = [
        "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]

      create_instance_profile = true
    }
  }

  tags = {
    "fv:environment" = "test"
    "fv:managed_by"  = "Terraform"
  }
}
