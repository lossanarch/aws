data "aws_ami" "coreos" {

  most_recent = true

  # name_regex       = "^coreos-stable.+"

  owners = ["595879546273"]

  filter {
    name   = "name"
    values = ["CoreOS-stable-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
