output "ec2_name" {
  description = "Nome da EC2 provisionada"
  value       = aws_instance.ec2_instance.tags["Name"]
}

output "ec2_id" {
  description = "ID da EC2 provisionada"
  value       = aws_instance.ec2_instance.id
}

output "ec2_arn" {
  description = "ARN da EC2 provisionada"
  value       = aws_instance.ec2_instance.arn
}

output "s3_name" {
  description = "Nome do bucket S3 que armazena a chave PEM"
  value       = aws_s3_bucket.ec2-bucket.bucket
}

output "s3_id" {
  description = "ID do bucket S3 que armazena a chave PEM"
  value       = aws_s3_bucket.ec2-bucket.id
}

output "iam_arn" {
  description = "ARN da role IAM que foi criada"
  value       = aws_iam_instance_profile.ec2-instance-profile.arn
}