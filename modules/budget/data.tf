data "aws_caller_identity" "current" {}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/scripts/lambda.py"
  output_path = "${path.module}/scripts/lambda.zip"
}