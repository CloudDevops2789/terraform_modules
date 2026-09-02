data "aws_vpc" "selected" {
  count = var.automation_mesh_enabled ? 1 : 0
  id    = var.vpc_id
}

data "aws_subnet" "selected" {
  count = var.automation_mesh_enabled ? 1 : 0
  id    = var.subnet_id

  lifecycle {
    postcondition {
      condition     = self.vpc_id == var.vpc_id
      error_message = "The selected subnet does not belong to the selected VPC."
    }
  }
}

data "aws_ami" "selected" {
  count = var.automation_mesh_enabled ? 1 : 0

  filter {
    name   = "image-id"
    values = [var.ami_id]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_iam_instance_profile" "selected" {
  count = var.automation_mesh_enabled ? 1 : 0
  name  = var.instance_profile_name
}

data "aws_key_pair" "selected" {
  count    = var.automation_mesh_enabled && var.ssh_key_name != null ? 1 : 0
  key_name = var.ssh_key_name
}

data "aws_kms_key" "root_volume" {
  count  = var.automation_mesh_enabled && var.root_volume.kms_key_id != null ? 1 : 0
  key_id = var.root_volume.kms_key_id
}

module "execution_node_security_group" {
  source = "../../modules/security-group"

  security_groups = var.automation_mesh_enabled ? {
    execution-node = {
      name        = "${var.instance_name}-sg"
      description = "AAP Automation Mesh execution-node network policy"
      vpc_id      = data.aws_vpc.selected[0].id
    }
  } : {}

  tags = local.tags
}

module "execution_node_security_group_rules" {
  source = "../../modules/security-group-rule"

  rules = merge(
    local.ssh_ingress_rules,
    local.mesh_ingress_rules,
    local.egress_rules
  )
}

module "execution_node" {
  source = "../../modules/ec2"

  instances = var.automation_mesh_enabled ? {
    execution-node = {
      name          = var.instance_name
      ami           = data.aws_ami.selected[0].id
      instance_type = var.instance_type
      subnet_id     = data.aws_subnet.selected[0].id

      associate_public_ip_address = false
      monitoring                  = var.enable_detailed_monitoring
      disable_api_termination     = var.enable_termination_protection
      ebs_optimized               = var.enable_ebs_optimization

      key_name = (
        var.ssh_key_name == null
        ? null
        : data.aws_key_pair.selected[0].key_name
      )

      iam_instance_profile = data.aws_iam_instance_profile.selected[0].name

      vpc_security_group_ids = [
        module.execution_node_security_group.security_group_ids["execution-node"]
      ]

      root_block_device = {
        volume_size = var.root_volume.volume_size
        volume_type = "gp3"
        iops        = var.root_volume.iops
        throughput  = var.root_volume.throughput
        kms_key_id = (
          var.root_volume.kms_key_id == null
          ? null
          : data.aws_kms_key.root_volume[0].arn
        )
        encrypted             = true
        delete_on_termination = true
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
        instance_metadata_tags      = var.instance_metadata_tags
      }
    }
  } : {}

  tags = local.tags

  depends_on = [module.execution_node_security_group_rules]
}
