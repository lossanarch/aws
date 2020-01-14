
resource "aws_s3_bucket" "data" {
  bucket = var.s3_bucket
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expire_old_versions"
    enabled = true

    noncurrent_version_expiration {
      days = 30
    }

  }
}

