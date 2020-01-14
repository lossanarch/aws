resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name}-ec2"
  role = aws_iam_role.ec2.id
}

resource "aws_iam_role" "ec2" {
  name = "${var.name}-ec2"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "s3" {
  name = "s3-access"
  role = aws_iam_role.ec2.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${var.data_bucket_arn}",
        "${var.data_bucket_arn}/*"
        ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "route53" {
  name = "route53-upsert"
  role = aws_iam_role.ec2.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListHostedZonesByName"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
