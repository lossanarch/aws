resource "aws_launch_template" "main" {
  name_prefix   = var.name
  image_id      = data.aws_ami.coreos.id
  instance_type = "t3.small"

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
  }

  iam_instance_profile {
    name = "${var.name}-ec2"
  }

  instance_market_options {
    market_type = "spot"
    spot_options {
      block_duration = 60
    }
  }

  user_data = base64encode(var.name)
}

resource "aws_autoscaling_group" "main" {

  availability_zones = [
    "ap-southeast-2a",
    "ap-southeast-2b",
    "ap-southeast-2c",
  ]

  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.main.id
      }

      override {
        instance_type = "t3.small"
      }

      override {
        instance_type = "t2.small"
      }
    }
  }
}
