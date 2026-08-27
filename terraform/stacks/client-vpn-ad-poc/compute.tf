data "aws_ssm_parameter" "windows_ami" {
  name = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base"
}

module "key_pair" {
  source = "../../modules/key-pair"

  key_pairs = {
    "${local.name_prefix}-windows" = {
      public_key = var.public_key
    }
  }

  tags = local.tags
}

module "ec2" {
  source = "../../modules/ec2"

  instances = {
    windows-test = {
      name                         = "${local.name_prefix}-windows"
      ami                          = data.aws_ssm_parameter.windows_ami.value
      instance_type                = var.test_instance_type
      subnet_id                   = module.vpc.subnet_ids["directory-a"]
      associate_public_ip_address = false
      key_name                    = module.key_pair.key_names["${local.name_prefix}-windows"]
      vpc_security_group_ids = [
        module.security_group.security_group_ids["windows-test"]
      ]
    }
  }

  tags = local.tags
}
