terraform {
  backend "s3" {
    bucket = "lossanarch-tf-backend"
    key    = "terraform.tfstate"
    region = "ap-southeast-2"
    # kms_key_id     = "dummy"
    # encrypt        = true
    # dynamodb_table = "tf-backend-aws"
  }
}
