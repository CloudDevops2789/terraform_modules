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