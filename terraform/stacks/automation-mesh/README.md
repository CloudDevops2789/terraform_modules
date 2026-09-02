# Automation Mesh Stack

Creates one private Automation Mesh execution node, one security group, and the approved rules supplied by the caller. It consumes an existing VPC, subnet, AMI, instance profile, key pair, and optional KMS key; it does not manage those dependencies or DNS.

Use a separate backend key for each target account and environment. DNS registration and Automation Mesh software installation remain separate post-provisioning workflows.
