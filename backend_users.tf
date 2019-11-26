#
# Generate machine keys from console, not here
#

resource "aws_iam_user" "steveh" {
  name          = "steveh"
  path          = "/ops/"
  force_destroy = true
}

resource "aws_iam_user_policy_attachment" "steveh" {
  user       = aws_iam_user.steveh.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

