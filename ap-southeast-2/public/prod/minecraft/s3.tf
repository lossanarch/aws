locals {
  s3_bucket = "lossanarch-minecraft-data"
}

resource "aws_s3_bucket" "data" {
  bucket = local.s3_bucket
  acl    = "private"
}
