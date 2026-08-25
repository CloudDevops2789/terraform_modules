locals {
  ##################################################################################################
  # Recovery Compute
  ##################################################################################################

  recovery_used_ssh_key_pair_keys = toset([
    for workload in values(var.recovery_workloads) :
    workload.ssh_key_pair_key
    if contains(
      ["ssh_key", "ssm_with_ssh_fallback"],
      workload.access_method
    )
  ])

  recovery_managed_ssh_key_pairs = {
    for key_name, config in var.recovery_ssh_key_pairs :
    key_name => config
    if(
      var.demo_ec2_enabled &&
      config.source == "managed" &&
      contains(local.recovery_used_ssh_key_pair_keys, key_name)
    )
  }

  recovery_existing_ssh_key_pairs = {
    for key_name, config in var.recovery_ssh_key_pairs :
    key_name => config
    if(
      var.demo_ec2_enabled &&
      config.source == "existing" &&
      contains(local.recovery_used_ssh_key_pair_keys, key_name)
    )
  }

  recovery_ssh_key_names = merge(
    {
      for key_name, key_pair in data.aws_key_pair.recovery_existing :
      key_name => key_pair.key_name
    },
    module.key_pair.key_names
  )
}
