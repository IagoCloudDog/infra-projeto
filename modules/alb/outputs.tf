output "alb_https_listener_arn" {
  value       = length(aws_lb_listener.https_listener) > 0 ? aws_lb_listener.https_listener[0].arn : null
  description = "ARN do listener HTTPS do ALB (porta 443)."
}

output "alb_http_listener_arn" {
  value       = aws_lb_listener.http_listener.arn
  description = "ARN do listener HTTP do ALB (porta 80)."
}

output "alb_endpoint" {
  value       = aws_lb.alb.dns_name
  description = "Endpoint DNS público do ALB."
}

output "alb_arn" {
  value       = aws_lb.alb.arn
  description = "ARN do Application Load Balancer."
}

output "alb_name" {
  value       = aws_lb.alb.name
  description = "Nome do Application Load Balancer."
}

output "alb_zone_id" {
  value       = aws_lb.alb.zone_id
  description = "ID da zona do ALB"
}

output "target_group_arn" {
  value = aws_lb_target_group.alb_target_group.arn
}

output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "DNS name do ALB"
}

output "target_group_arn_suffix" {
  value       = aws_lb_target_group.alb_target_group.arn_suffix
  description = "ARN Suffix do Target Group"
}

output "alb_arn_suffix" {
  value       = aws_lb.alb.arn_suffix
  description = "ARN Suffix do ALB"
}

output "alb_id" {
  value       = aws_lb.alb.id
  description = "ID do ALB"
}