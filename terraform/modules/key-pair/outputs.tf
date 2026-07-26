# Returned as maps keyed by the caller's own names. key_names is the
# output the ec2 module consumes, since aws_instance.key_name expects the
# key's NAME, not its ID.
output "key_names" {
  description = "Map of key pair names."

  value = {
    for name, key in aws_key_pair.this :
    name => key.key_name
  }
}

output "key_ids" {
  description = "Map of key pair IDs."

  value = {
    for name, key in aws_key_pair.this :
    name => key.id
  }
}