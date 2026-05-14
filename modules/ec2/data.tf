#========================================================================================#
#                                   AMI DATAS                                            #
#========================================================================================#

data "aws_ami" "ubuntu_arm64" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

data "aws_ami" "ubuntu_jammy_amd64" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

#========================================================================================#
#                                  TEMPLATE DATA                                         #
#========================================================================================#

data "template_file" "cloudwatch_agent" {
  template = file(lookup(local.cloudwatch_templates, var.os_arch, "templates/ubuntu_amd64.sh"))
  vars = {
    PHP_VERSION       = var.php_version
    APP_DOMAIN        = var.app_domain
    APP_PATH          = "/var/www/${var.app_domain}"
    DB_HOST           = var.db_host
    DB_USER           = var.db_user
    DB_NAME           = var.db_name
    EFS_ID            = var.efs_id
    REDIS_HOST        = var.redis_host
    SECRETS_ARN       = var.secrets_arn
    SECRETS_WP        = aws_secretsmanager_secret.wordpress_secrets.arn
    SECRETS_SFTP      = var.enable_sftp ? aws_secretsmanager_secret.sftp_secrets[0].arn : ""
    AWS_REGION        = var.region
    CLOUDFRONT_DOMAIN = var.cloudfront_domain
  }
}