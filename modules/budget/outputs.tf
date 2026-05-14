# Outputs
output "sns_topic_arn" {
  description = "ARN do tópico SNS para alertas de orçamento"
  value       = aws_sns_topic.budget_sns_topic.arn
}

output "lambda_arn" {
  description = "ARN da função Lambda de notificação"
  value       = aws_lambda_function.budget_notification_lambda.arn
}