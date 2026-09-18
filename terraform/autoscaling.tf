resource "aws_autoscaling_group" "web" {
  name             = "${var.project_name}-web-asg"
  min_size         = 2
  desired_capacity = 2
  max_size         = 6

  vpc_zone_identifier = [
    aws_subnet.web_a.id,
    aws_subnet.web_b.id
  ]

  target_group_arns = [
    aws_lb_target_group.web.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 180

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 180
    }
  }
}

resource "aws_autoscaling_policy" "web_cpu_target" {
  name                   = "${var.project_name}-web-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }

  estimated_instance_warmup = 180
}