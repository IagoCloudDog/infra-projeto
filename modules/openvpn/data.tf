#========================================================================================#
#                                   AMI DATAS                                            #
#========================================================================================#

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}



#========================================================================================#
#                                  TEMPLATE DATA                                         #
#========================================================================================#

data "template_file" "user_data" {
  template = file("${path.module}/templates/user_data.sh")

  vars = {
    CUSTOMER_NAME   = var.customer_name
    VPC_RANGE       = var.vpc_range
    AWS_REGION      = var.region
    SECRETS_OPENVPN = aws_secretsmanager_secret.openvpn_secrets.arn
  }
}