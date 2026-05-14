#========================================================================================#
#                                  BUDGET RESOURCES                                      #
#========================================================================================#

# DAILY BUDGET RESOURCE
resource "aws_budgets_budget" "daily_budget" {
  name         = "${var.customer_name}-${var.environment_name}-Daily-Budget"
  budget_type  = "COST"
  limit_amount = var.daily_budget_value
  limit_unit   = "USD"
  time_unit    = "DAILY"

  cost_types {
    include_tax                = true
    include_subscription       = true
    use_blended                = false
    include_refund             = true
    include_credit             = false
    include_upfront            = true
    include_recurring          = true
    include_other_subscription = true
    include_support            = true
    include_discount           = true
    use_amortized              = false
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    notification_type         = "ACTUAL"
    threshold                 = 99
    threshold_type            = "PERCENTAGE"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_sns_topic.arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    notification_type         = "ACTUAL"
    threshold                 = 85
    threshold_type            = "PERCENTAGE"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_sns_topic.arn]
  }

  cost_filter {
    name = "TagKeyValue"
    values = [
      "user:${var.budget_filter_tag}${"$"}${var.budget_filter_value}"
    ]
  }

  tags = merge(local.tags, {})
}

# MONTHLY BUDGET RESOURCE
resource "aws_budgets_budget" "monthly_budget" {
  name         = "${var.customer_name}-${var.environment_name}-Monthly-Budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_value
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_types {
    include_tax                = true
    include_subscription       = true
    use_blended                = false
    include_refund             = true
    include_credit             = false
    include_upfront            = true
    include_recurring          = true
    include_other_subscription = true
    include_support            = true
    include_discount           = true
    use_amortized              = false
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    notification_type         = "ACTUAL"
    threshold                 = 99
    threshold_type            = "PERCENTAGE"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_sns_topic.arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    notification_type         = "ACTUAL"
    threshold                 = 85
    threshold_type            = "PERCENTAGE"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_sns_topic.arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    notification_type         = "FORECASTED"
    threshold                 = 105
    threshold_type            = "PERCENTAGE"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_sns_topic.arn]
  }

  cost_filter {
    name = "TagKeyValue"
    values = [
      "user:${var.budget_filter_tag}${"$"}${var.budget_filter_value}"
    ]
  }

  tags = merge(local.tags, {})
}

#========================================================================================#
#                                  SNS RESOURCES                                         #
#========================================================================================#

# SNS Topic para Budget Alerts
resource "aws_sns_topic" "budget_sns_topic" {
  name = "${var.customer_name}-${var.environment_name}-lambda-topic"
}

# Política SNS
resource "aws_sns_topic_policy" "budget_sns_topic_policy" {
  arn = aws_sns_topic.budget_sns_topic.arn
  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid       = "__default_statement_ID"
        Effect    = "Allow"
        Principal = { "AWS" : "*" }
        Action = [
          "SNS:GetTopicAttributes",
          "SNS:SetTopicAttributes",
          "SNS:AddPermission",
          "SNS:RemovePermission",
          "SNS:DeleteTopic",
          "SNS:Subscribe",
          "SNS:ListSubscriptionsByTopic",
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.budget_sns_topic.arn
        Condition = {
          StringEquals = {
            "AWS:SourceOwner" = "${data.aws_caller_identity.current.account_id}"
          }
        }
      },
      {
        Sid       = "AWSBudgets-notification"
        Effect    = "Allow"
        Principal = { "Service" : "budgets.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.budget_sns_topic.arn
      }
    ]
  })

}

resource "aws_sns_topic_subscription" "subscriptions" {
  topic_arn = aws_sns_topic.budget_sns_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.budget_notification_lambda.arn
}

# Novo tópico SNS para mensagens processadas pela Lambda
resource "aws_sns_topic" "budget_processed_topic" {
  name = "${var.customer_name}-${var.environment_name}-budget-processed-topic"

  tags = merge(local.tags, {})
}

# Política do tópico processado (caso precise permitir outras fontes no futuro)
resource "aws_sns_topic_policy" "budget_processed_topic_policy" {
  arn = aws_sns_topic.budget_processed_topic.arn
  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid       = "__default_statement_ID"
        Effect    = "Allow"
        Principal = { "AWS" : "*" }
        Action = [
          "SNS:GetTopicAttributes",
          "SNS:SetTopicAttributes",
          "SNS:AddPermission",
          "SNS:RemovePermission",
          "SNS:DeleteTopic",
          "SNS:Subscribe",
          "SNS:ListSubscriptionsByTopic",
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.budget_processed_topic.arn
        Condition = {
          StringEquals = {
            "AWS:SourceOwner" = "${data.aws_caller_identity.current.account_id}"
          }
        }
      }
    ]
  })
}

# (Opcional) Subscrições no tópico processado — ex: email, webhook, Teams, etc.
resource "aws_sns_topic_subscription" "processed_subscriptions" {
  for_each  = var.budget_subscriptions
  topic_arn = aws_sns_topic.budget_processed_topic.arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
}

#========================================================================================#
#                                  LAMBDA RESOURCES                                      #
#========================================================================================#

# Função Lambda para processamento de notificações
resource "aws_lambda_function" "budget_notification_lambda" {
  function_name = "${var.customer_name}-${var.environment_name}-budget-function"
  handler       = "index.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_execution_role.arn
  timeout       = 60

  environment {
    variables = {
      SNS_TOPIC_ARN           = aws_sns_topic.budget_sns_topic.arn
      SNS_PROCESSED_TOPIC_ARN = aws_sns_topic.budget_processed_topic.arn
      CUSTOMER_NAME           = var.customer_name
      ACCOUNT_ID              = data.aws_caller_identity.current.account_id
      MENSAL_BUDGET_VALUE     = var.monthly_budget_value
      DAILY_BUDGET_VALUE      = var.daily_budget_value
    }
  }

  filename = data.archive_file.lambda_zip.output_path

  tags = merge(local.tags, {})
}

# Permissões para Lambda invocada pelo SNS
resource "aws_lambda_permission" "lambda_invoke_permission" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.budget_notification_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.budget_sns_topic.arn
}

#========================================================================================#
#                               ROLE/POLICY RESOURCES                                    #
#========================================================================================#

# Função IAM para Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.customer_name}-${var.environment_name}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { "Service" : "lambda.amazonaws.com" }
    }]
  })

  tags = merge(local.tags, {})
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "LambdaExecutionPolicy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "sns:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}