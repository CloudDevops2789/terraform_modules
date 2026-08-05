module "key_pair" {

  source = "../../../modules/key-pair"

  tags = local.org_tags
  key_pairs = {

    management = {
      public_key = file(var.public_key_path)
    }

  }

}