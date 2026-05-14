#========================================================================================#
#                              AMIs / USER_DATA LOCALS                                   #
#========================================================================================#

locals {
  cloudwatch_templates = {
    "graviton" = "${path.module}/templates/graviton.sh"
    "x86"      = "${path.module}/templates/x86.sh"
  }
}

locals {
  ami_map = {
    "graviton" = data.aws_ami.ubuntu_arm64.id
    "x86"      = data.aws_ami.ubuntu_jammy_amd64.id
  }
}

locals {
  tags = var.tags
}