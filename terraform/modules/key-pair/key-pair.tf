# One EC2 key pair per entry of var.key_pairs. The map key doubles as the
# key_name in AWS, so the name a caller uses in Terraform is the name they
# will see in the console.
#
# Only the PUBLIC half of the key is ever sent to AWS or stored in state.
# The private key stays with the operator, which is why this module takes
# public_key as an input rather than generating a keypair itself.
resource "aws_key_pair" "this" {
  for_each = var.key_pairs

  key_name   = each.key
  public_key = each.value.public_key

  tags = local.tags[each.key]
}