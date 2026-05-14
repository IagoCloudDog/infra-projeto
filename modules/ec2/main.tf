

#========================================================================================#
#                           PRIVATE / PAIR KEY RESOURCES                                 #
#========================================================================================#

resource "tls_private_key" "ec2-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2-key" {
  key_name   = "${var.customer_name}-wordpress-${var.environment_name}"
  public_key = tls_private_key.ec2-key.public_key_openssh

  tags = merge(local.tags, {})
}

#========================================================================================#
#                                  EC2 RESOURCES                                         #
#========================================================================================#

resource "aws_instance" "ec2_instance" {
  ami           = lookup(local.ami_map, var.os_arch, data.aws_ami.ubuntu_jammy_amd64.id)
  instance_type = var.instance_type
  key_name      = aws_key_pair.ec2-key.key_name

  iam_instance_profile = aws_iam_instance_profile.ec2-instance-profile.name

  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]

  user_data = data.template_file.cloudwatch_agent.rendered

  associate_public_ip_address = var.public_ip

  root_block_device {
    volume_type           = var.volume_type
    volume_size           = var.volume_size
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(local.tags, {
    Name           = "${var.customer_name}-wordpress-${var.environment_name}-ec2",
    OS             = "Linux",
    Backup-Daily   = var.daily_backup,
    Backup-Weekly  = var.weekly_backup,
    Backup-Monthly = var.monthly_backup
  })
}

resource "aws_ssm_association" "install_efs_utils" {
  name = "AWS-ConfigureAWSPackage"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.ec2_instance.id]
  }

  parameters = {
    name   = "AmazonEFSUtils"
    action = "Install"
  }

  tags = merge(local.tags, {})
}

#========================================================================================#
#                               CREDENTIALS RESOURCE                                     #
#========================================================================================#

resource "aws_secretsmanager_secret" "wordpress_secrets" {
  name                    = "${var.customer_name}-wordpress-${var.environment_name}-secrets"
  description             = "${var.customer_name} secrets for Wordpress"
  recovery_window_in_days = 0

  tags = merge(local.tags, {})
}

resource "aws_secretsmanager_secret" "sftp_secrets" {

  count = var.enable_sftp ? 1 : 0

  name                    = "${var.customer_name}-sftp-${var.environment_name}-secrets"
  description             = "${var.customer_name} secrets for SFTP"
  recovery_window_in_days = 0

  tags = merge(local.tags, {})
}

#========================================================================================#
#                           ROLES AND POLICIES RESOURCES                                 #
#========================================================================================#

resource "aws_iam_role" "ec2-role-terraform" {
  name = "${var.customer_name}-wordpress-${var.environment_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.tags, {})
}

resource "aws_iam_policy" "ec2-policy-terraform" {
  name = "${var.customer_name}-wordpress-${var.environment_name}-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "elasticfilesystem:*",
          "ec2:*",
          "secretsmanager:*",
          "ssm:*",
          "s3:*",
          "ec2-instance-connect:SendSSHPublicKey"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "s3:*",
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.ec2-bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.ec2-bucket.bucket}/*",
        ]
      },
    ]
    }
  )
  tags = merge(local.tags, {})
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2-role-terraform.name
  policy_arn = aws_iam_policy.ec2-policy-terraform.arn
}

resource "aws_iam_instance_profile" "ec2-instance-profile" {
  name = "${var.customer_name}-wordpress-${var.environment_name}-profile"

  role = aws_iam_role.ec2-role-terraform.name

  tags = merge(local.tags, {})
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_agent_attachment" {
  role = aws_iam_role.ec2-role-terraform.name

  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#========================================================================================#
#                                  S3 RESOURCES                                          #
#========================================================================================#

resource "aws_s3_bucket" "ec2-bucket" {
  bucket = "${var.customer_name}-wordpress-${var.environment_name}-bucket"

  tags = merge(local.tags, {})
}

resource "aws_s3_object" "pastaChaveBucket" {
  bucket = aws_s3_bucket.ec2-bucket.bucket
  key    = "chave/"
  source = "/dev/null" # Usar um arquivo vazio para criar o "diretório"

  tags = merge(local.tags, {})
}

resource "aws_s3_object" "private-key-pair-file" {
  depends_on = [aws_s3_object.pastaChaveBucket]

  bucket  = aws_s3_bucket.ec2-bucket.bucket
  key     = format("chave/%s/%s.pem", aws_instance.ec2_instance.id, aws_key_pair.ec2-key.key_name)
  content = tls_private_key.ec2-key.private_key_pem # Usar 'content' ao invés de 'source'

  tags = merge(local.tags, {})
}