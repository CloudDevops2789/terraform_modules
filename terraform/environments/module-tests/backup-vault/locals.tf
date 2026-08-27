locals {

  ##################################################################################################
  # Common Tags
  ##################################################################################################
  org_required_tags = {
    "org_it_cost_center"       = var.org_it_cost_center
    "org_department"           = var.org_department
    "org_cmdb_calculated_app"  = var.org_cmdb_calculated_app
    "org_business_criticality" = var.org_business_criticality
    "org_environment"          = var.org_environment
    "org_data_classification"  = var.org_data_classification
    "org_project_name"         = var.org_project_name
    "org_managed_by"           = var.org_managed_by
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
    vpc_name   = "module-test-backup-vpc"
    cidr_block = "10.255.0.0/16"

    route_tables = {
      private-a = {
        group = "supporting"
      }
    }

    subnets = {
      private-a = {
        cidr_block              = "10.255.11.0/24"
        availability_zone_index = 0
        group                   = "supporting"
        route_table_key         = "private-a"
      }
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
    # Standard AWS Backup vault used for primary recovery points.
    standard_vault_name = "module-test-standard-backup-vault"

    # Logically air-gapped vault used as the immutable destination
    # for copies created by the backup plan.
    air_gapped_vault_name = "module-test-airgap-backup-vault"

    # Minimum and maximum retention limits enforced by the
    # logically air-gapped vault.
    #
    # The maximum was increased from 30 to 90 days because the backup
    # plan retains copied cyber-recovery recovery points for 90 days.
    # Copy-action retention must remain within the vault's configured
    # minimum and maximum retention limits.
    air_gapped_min_retention_days = 7
    air_gapped_max_retention_days = 90

    # Name of the AWS Backup plan under test.
    plan_name = "module-test-backup-plan"

    # IAM role assumed by AWS Backup when protecting the selected resources.
    role_name = "module-test-backup-role"

    # Name of the backup selection that associates the supporting
    # EC2 instance with the backup plan.
    selection_name = "module-test-backup-selection"

    plan_rules = {
      daily = {
        # Run the backup job every day at 05:00 UTC.
        schedule = "cron(0 5 ? * * *)"

        # AWS Backup must start the job within 60 minutes
        # of the scheduled start time.
        start_window = 60

        # AWS Backup must complete the job within 180 minutes
        # after the job starts.
        completion_window = 180

        # Move the primary recovery point to cold storage
        # after 30 days.
        cold_storage_after = 30

        # Changed from 90 to 120 days.
        #
        # AWS Backup requires a recovery point moved to cold storage
        # to remain in cold storage for at least 90 days.
        #
        # 30 days before transition + 90 days in cold storage
        # = 120 days minimum total retention.
        delete_after = 120

        # Retain the copy stored in the logically air-gapped vault
        # for 90 days.
        #
        # This value must be between the vault's configured minimum
        # and maximum retention limits of 7 and 90 days.
        cyber_recovery_delete_after = 90
      }
    }
  }
}
