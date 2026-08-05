locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  org_required_tags = {
    org_it_cost_center       = var.org_it_cost_center
    org_department           = var.org_department
    org_cmdb_calculated_app  = var.org_cmdb_calculated_app
    org_business_criticality = var.org_business_criticality
    org_environment          = var.org_environment
    org_data_classification  = var.org_data_classification
    org_project_name         = var.org_project_name
    org_managed_by           = var.org_managed_by
  }

  org_tags = merge(
    var.org_additional_tags,
    local.org_required_tags
  )

  ##################################################################################################
  # Supporting VPC
  ##################################################################################################
  # AWS Backup protects existing resources - it needs a real resource ARN
  # to select. A minimal VPC and instance exist only to give the Backup
  # Selection module something to protect; neither is under test.
  vpc = {
    vpc_name                = "module-test-backup-vpc"
    cidr_block              = "10.255.0.0/16"
    availability_zone_count = 2

    private_subnets = {
      private-a = "10.255.11.0/24"
    }
  }

  ##################################################################################################
  # Supporting Security Group
  ##################################################################################################
  security_group = {
    description = "Module test - Backup workload"
  }

  ##################################################################################################
  # Supporting EC2 Instance
  ##################################################################################################
  # The single resource protected by the Backup Selection under test.
  ec2 = {
    ami                         = "ami-00adf8f2fe708c532" # Amazon Linux 2023 (x86_64) - us-east-1
    instance_type               = "t3.micro"
    associate_public_ip_address = false
  }

  ##################################################################################################
  # Backup Under Test
  ##################################################################################################
  # Static AWS Backup configuration exercising all five backup modules
  # together, exactly as they are composed in sandbox: a standard vault, a
  # logically air-gapped vault for immutable copies, the IAM role AWS
  # Backup assumes, a plan with a daily rule and a copy action, and a
  # selection binding the supporting EC2 instance to that plan.
  backup = {
    standard_vault_name = "module-test-standard-backup-vault"

    air_gapped_vault_name         = "module-test-airgap-backup-vault"
    air_gapped_min_retention_days = 7
    air_gapped_max_retention_days = 30

    plan_name = "module-test-backup-plan"

    role_name = "module-test-backup-role"

    selection_name = "module-test-backup-selection"

    plan_rules = {
      daily = {
        schedule          = "cron(0 5 ? * * *)"
        start_window      = 60
        completion_window = 180

        cold_storage_after = 30
        delete_after       = 90

        cyber_recovery_delete_after = 90
      }
    }
  }
}
