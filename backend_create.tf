resource "aws_s3_bucket" "backend" {
  bucket = "lossanarch-tf-backend"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name = "lossanarch-tf-backend"
  }
}

locals {
  tf_state_user_arns = [
    aws_iam_user.steveh.arn,
  ]
}

resource "aws_s3_bucket_policy" "backend" {
  bucket = aws_s3_bucket.backend.id

  policy = <<POLICY
{
"Version": "2012-10-17",
    "Statement": [
{
     "Sid": "WhitelistListAccess",
     "Effect": "Deny",
     "NotPrincipal": {
          "AWS": [
               "${join("\",\"", local.tf_state_user_arns)}"
          ]
     },
     "Action": [
          "s3:ListBucket"
     ],
     "Resource": "${aws_s3_bucket.backend.arn}"
},
{
     "Sid": "WhitelistBucketAccess",
     "Effect": "Deny",
     "NotPrincipal": {
          "AWS": [
               "${join("\",\"", local.tf_state_user_arns)}"
          ]
     },
     "Action": [
          "s3:PutObject",
          "s3:GetObject"
     ],
     "Resource": "${aws_s3_bucket.backend.arn}/*"
},
{
     "Sid": "WhitelistBucketPolicyModify",
     "Effect": "Deny",
     "NotPrincipal": {
          "AWS": [
               "${join("\",\"", local.tf_state_user_arns)}"
          ]
     },
     "Action": [
          "s3:PutBucketPolicy",
          "s3:GetBucketPolicy"
     ],
     "Resource": "${aws_s3_bucket.backend.arn}"
}
]
}
POLICY

}

