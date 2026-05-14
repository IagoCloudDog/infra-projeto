#========================================================================================#
#                               LAUNCH TEMPLATE RESOURCES                                #
#========================================================================================#

resource "aws_ami_from_instance" "ami_lt" {
  count              = var.enable_asg ? 1 : 0
  name               = "${var.customer_name}-wordpress-${var.environment_name}-asg-ami"
  source_instance_id = var.ec2_instance_id

  snapshot_without_reboot = true

  tags = merge(local.tags, {
    Name = "${var.customer_name}-wordpress-${var.environment_name}-asg-ami"
  })
}

resource "aws_ec2_instance_state" "stop_instance" {
  depends_on = [aws_ami_from_instance.ami_lt]

  instance_id = var.ec2_instance_id
  state       = "stopped"
}

resource "aws_launch_template" "launch_template" {
  count         = var.enable_asg ? 1 : 0
  name          = "${var.customer_name}-wordpress-${var.environment_name}-lt"
  image_id      = aws_ami_from_instance.ami_lt[0].id
  instance_type = var.lt_instance_type

  instance_market_options {
    market_type = "spot"
  }

  iam_instance_profile {
    arn = var.ec2_iam_instance_profile_arn
  }

  vpc_security_group_ids = [var.ec2_security_group_id]


  tag_specifications {
    resource_type = "instance"
    tags = merge(local.tags, {
      Name           = "${var.customer_name}-wordpress-${var.environment_name}-ec2"
      Backup-Daily   = var.daily_backup,
      Backup-Weekly  = var.weekly_backup,
      Backup-Monthly = var.monthly_backup
    })
  }

  tags = merge(local.tags, {})
}

resource "aws_autoscaling_group" "autoscaling_group" {
  count = var.enable_asg ? 1 : 0
  name  = "${var.customer_name}-wordpress-${var.environment_name}-asg"

  target_group_arns   = var.target_group_arns
  desired_capacity    = var.instances_desired_capacity
  min_size            = var.instances_min_size
  max_size            = var.instances_max_size
  vpc_zone_identifier = var.vpc_zone_identifier

  health_check_type         = var.on_demand_health_check_type
  health_check_grace_period = var.health_check_grace_period

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  launch_template {
    id      = aws_launch_template.launch_template[0].id
    version = "$Latest"
  }
}

#========================================================================================#
#                              AUTO SCALING POLICY RESOURCES                             #
#========================================================================================#

resource "aws_autoscaling_policy" "scale_config" {
  count = var.enable_asg && (var.enable_cpu_scaling || var.enable_network_scaling) ? 1 : 0

  name                      = "${var.customer_name}-wordpress-${var.environment_name}-scale-policy"
  policy_type               = "TargetTrackingScaling"
  adjustment_type           = "ChangeInCapacity"
  estimated_instance_warmup = var.scale_config_warmup
  autoscaling_group_name    = aws_autoscaling_group.autoscaling_group[0].name

  target_tracking_configuration {
    target_value = var.enable_cpu_scaling ? var.cpu_target_value : var.alb_target_value

    dynamic "predefined_metric_specification" {
      for_each = var.enable_network_scaling ? [1] : []

      content {
        predefined_metric_type = "ALBRequestCountPerTarget"
        resource_label         = "${var.alb_load_balancer_arn_suffix}/${var.alb_target_group_arn_suffix}"
      }
    }

    dynamic "customized_metric_specification" {
      for_each = var.enable_cpu_scaling ? [1] : []

      content {
        namespace   = "AWS/EC2"
        metric_name = "CPUUtilization"
        statistic   = "Maximum"
        unit        = "Percent"
        metric_dimension {
          name  = "AutoScalingGroupName"
          value = aws_autoscaling_group.autoscaling_group[0].name
        }
      }
    }
  }
}

