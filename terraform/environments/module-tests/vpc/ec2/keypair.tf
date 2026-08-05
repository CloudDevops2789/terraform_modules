module "key_pair" {

  source = "../../../modules/key-pair"

  default_tags = local.default_tags

  key_pairs = {

    management = {
      public_key = file(var.public_key_path)
    }

  }

}