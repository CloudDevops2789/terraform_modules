# The IDs are what every consumer needs: the security-group-rule module
# attaches rules to them, and the ec2 module attaches instances to them.
output "security_group_ids" {

  description = "Security group IDs."

  value = {
    for name, sg in aws_security_group.this :
    name => sg.id
  }

}