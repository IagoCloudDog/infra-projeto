#========================================================================================#
#                           ROLES AND POLICIES RESOURCES                                 #
#========================================================================================#

resource "aws_iam_role" "ec2-role-terraform" {
  name = "${var.customer_name}-openvpn-${var.environment_name}-role"
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
  name = "${var.customer_name}-openvpn-${var.environment_name}-policy"
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
          "arn:aws:s3:::${aws_s3_bucket.openvpn_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.openvpn_bucket.bucket}/*",
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
  name = "${var.customer_name}-openvpn-${var.environment_name}-profile"

  role = aws_iam_role.ec2-role-terraform.name

  tags = merge(local.tags, {})
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_agent_attachment" {
  role = aws_iam_role.ec2-role-terraform.name

  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#========================================================================================#
#                           PRIVATE / PAIR KEY RESOURCES                                 #
#========================================================================================#

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = format("%s-key", var.customer_name)
  public_key = tls_private_key.private_key.public_key_openssh

  tags = merge(local.tags, {})
}

#========================================================================================#
#                                  S3 RESOURCES                                          #
#========================================================================================#

resource "aws_s3_bucket" "openvpn_bucket" {
  bucket        = "${var.customer_name}-openvpn-${var.environment_name}-bucket"
  force_destroy = true

  tags = merge(local.tags, {})
}

resource "aws_s3_object" "key_path" {
  bucket = aws_s3_bucket.openvpn_bucket.bucket
  key    = "chave/"
  source = "/dev/null" # Usar um arquivo vazio para criar o "diretório"

  tags = merge(local.tags, {})
}

resource "aws_s3_object" "key_pair_put" {
  depends_on = [aws_s3_object.key_path]

  bucket  = aws_s3_bucket.openvpn_bucket.bucket
  key     = format("chave/%s/%s.pem", aws_instance.openvpn.id, aws_key_pair.key_pair.key_name)
  content = tls_private_key.private_key.private_key_pem

  tags = merge(local.tags, {})
}

#========================================================================================#
#                               CREDENTIALS RESOURCE                                     #
#========================================================================================#

resource "aws_secretsmanager_secret" "openvpn_secrets" {
  name                    = "${var.customer_name}-openvpn-${var.environment_name}-secrets"
  description             = "${var.customer_name} secrets for OpenVPN"
  recovery_window_in_days = 0

  tags = merge(local.tags, {})
}

#========================================================================================#
#                                  EC2 RESOURCES                                         #
#========================================================================================#

resource "aws_instance" "openvpn" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.key_pair.key_name

  iam_instance_profile = aws_iam_instance_profile.ec2-instance-profile.name

  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.security_group_id]

  ipv6_address_count = 0

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.volume_size
    delete_on_termination = true
    encrypted             = true
  }

  user_data = data.template_file.user_data.rendered

  tags = merge(local.tags, {
    Name = "${var.customer_name}-openvpn-${var.environment_name}-ec2",
    OS   = "Linux"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip" "openvpn_eip" {
  instance = aws_instance.openvpn.id
  domain   = "vpc"

  tags = {
    Name = "openvpn-eip"
  }
}
