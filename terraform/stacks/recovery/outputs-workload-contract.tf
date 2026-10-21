################################################################################
# Recovery Workload Runtime Contract
#
# Exposes only the runtime attributes required by operational automation.
#
# Consumers select workloads by logical workload key. They must not reconstruct
# EC2 instance IDs, infer operating systems from AMIs, or depend on EC2 naming.
################################################################################

output "recovery_workload_contract" {
  description = "Runtime Recovery workload inventory keyed by logical workload name."

  value = (
    var.demo_ec2_enabled
    ? {
      for workload_key, workload in var.recovery_workloads :
      workload_key => {
        instance_id = module.ec2.instance_ids[workload_key]

        server_name = coalesce(
          workload.server_name,
          workload_key
        )

        platform      = workload.platform
        access_method = workload.access_method
      }
    }
    : {}
  )
}
