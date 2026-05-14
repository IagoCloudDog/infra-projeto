output "autoscaling_name" {
  value = var.enable_asg ? aws_autoscaling_group.autoscaling_group[0].name : null
}