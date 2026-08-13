locals {
  ##################################################################################################
  # EC2
  ##################################################################################################
  # Static instance configuration shared by the one representative instance
  # deployed per tier: AMI, instance type, and public IP posture. Placement
  # (subnet_id), key material, and security group membership are relationships
  # and remain in compute.tf.
  ec2 = {
    ami                         = var.ami_id # Amazon Linux 2023 (x86_64) - us-east-1
    instance_type               = "t3.micro"
    associate_public_ip_address = false

  }
}
