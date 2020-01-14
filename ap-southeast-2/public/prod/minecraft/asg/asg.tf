resource "aws_launch_template" "main" {
  name_prefix   = var.name
  image_id      = data.aws_ami.coreos.id
  instance_type = "t3a.medium"

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = var.security_groups
  }

  iam_instance_profile {
    name = "${var.name}-ec2"
  }

  key_name = var.key_pair_name

  # instance_market_options {
  # market_type = "spot"
  # spot_options {
  #   block_duration = 60
  # }
  # }

  user_data = var.user_data_base64
}

resource "aws_autoscaling_group" "main" {

  availability_zones = [
    "ap-southeast-2a",
    "ap-southeast-2b",
    "ap-southeast-2c",
  ]

  desired_capacity = 1
  max_size         = 1
  min_size         = 0

  mixed_instances_policy {

    instances_distribution {
      on_demand_percentage_above_base_capacity = 0
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.main.id
        version            = aws_launch_template.main.latest_version
      }

      override {
        instance_type = "t3a.medium"
      }

      override {
        instance_type = "t3.medium"
      }
    }
  }

  wait_for_capacity_timeout = 0
}
