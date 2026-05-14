#========================================================================================#
#                               LOAD BALANCER SG RESOURCES                               #
#========================================================================================#

resource "aws_security_group" "alb_sg" {
  count       = var.config.create_alb_security_group ? 1 : 0
  name        = "${var.customer_name}-${var.environment_name}-alb-sg"
  vpc_id      = var.vpc_id
  description = "Application Load Balancer Security Group"
  tags = merge(local.tags, {
    Name = "${var.customer_name}-${var.environment_name}-alb-sg"
  })
}

resource "aws_security_group_rule" "allow_443_ipv4_ingress" {
  count             = var.config.create_alb_security_group ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.alb_sg[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  description       = "Allow all-traffic from Internet to TLS port"
}

resource "aws_security_group_rule" "allow_80_ipv4_ingress" {
  count             = var.config.create_alb_security_group ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.alb_sg[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  description       = "Allow all-traffic from Internet to HTTP port"
}

resource "aws_security_group_rule" "allow_egress_to_app" {
  count                    = var.config.create_alb_security_group && var.config.create_app_security_group ? 1 : 0
  type                     = "egress"
  security_group_id        = aws_security_group.alb_sg[0].id
  source_security_group_id = aws_security_group.app_sg[0].id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  description              = "Allow All Traffic to Application"
}

resource "aws_security_group_rule" "allow_egress_to_openvpn" {
  count                    = var.config.create_alb_security_group && var.config.create_vpn_security_group ? 1 : 0
  type                     = "egress"
  security_group_id        = aws_security_group.alb_sg[0].id
  source_security_group_id = aws_security_group.openvpn_sg[0].id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  description              = "Allow All Traffic to OpenVPN"
}

#========================================================================================#
#                               LOAD BALANCER SG RESOURCES                               #
#========================================================================================#

resource "aws_security_group" "nlb_sg" {
  count       = var.config.create_alb_security_group ? 1 : 0
  name        = "${var.customer_name}-${var.environment_name}-nlb-sg"
  vpc_id      = var.vpc_id
  description = "Network Load Balancer Security Group"
  tags = merge(local.tags, {
    Name = "${var.customer_name}-${var.environment_name}-nlb-sg"
  })
}

resource "aws_security_group_rule" "allow_21_ipv4_ingress" {
  count             = var.config.create_nlb_security_group ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.nlb_sg[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  protocol          = "tcp"
  to_port           = 22
  description       = "Allow all-traffic from Internet to SFTP port"
}

resource "aws_security_group_rule" "allow_nlb_egress_to_app" {
  count                    = var.config.create_nlb_security_group && var.config.create_app_security_group ? 1 : 0
  type                     = "egress"
  security_group_id        = aws_security_group.nlb_sg[0].id
  source_security_group_id = aws_security_group.app_sg[0].id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  description              = "Allow All Traffic to Application"
}

resource "aws_security_group_rule" "allow_nlb_egress_to_openvpn" {
  count                    = var.config.create_nlb_security_group && var.config.create_vpn_security_group ? 1 : 0
  type                     = "egress"
  security_group_id        = aws_security_group.nlb_sg[0].id
  source_security_group_id = aws_security_group.openvpn_sg[0].id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  description              = "Allow All Traffic to OpenVPN"
}

#========================================================================================#
#                               APPLICATION SG RESOURCES                                 #
#========================================================================================#

resource "aws_security_group" "app_sg" {
  count       = var.config.create_app_security_group ? 1 : 0
  name        = "${var.customer_name}-${var.environment_name}-app-sg"
  vpc_id      = var.vpc_id
  description = "Application Security Group"
  tags = merge(local.tags, {
    Name = "${var.customer_name}-${var.environment_name}-app-sg"
  })
}

resource "aws_security_group_rule" "allow_alb_ingress_to_app" {
  count                    = (var.config.create_app_security_group && var.config.create_alb_security_group) ? 1 : 0
  type                     = "ingress"
  depends_on               = [aws_security_group.alb_sg, aws_security_group.app_sg]
  security_group_id        = aws_security_group.app_sg[0].id
  source_security_group_id = aws_security_group.alb_sg[0].id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  description              = "Allow ALB Ingress"
}

resource "aws_security_group_rule" "allow_nlb_ingress_to_app" {
  count                    = (var.config.create_app_security_group && var.config.create_nlb_security_group) ? 1 : 0
  type                     = "ingress"
  depends_on               = [aws_security_group.nlb_sg, aws_security_group.app_sg]
  security_group_id        = aws_security_group.app_sg[0].id
  source_security_group_id = aws_security_group.nlb_sg[0].id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  description              = "Allow NLB Ingress"
}

resource "aws_security_group_rule" "allow_db_ingress_to_app" {
  count                    = var.config.create_app_security_group && var.config.create_db_security_group ? 1 : 0
  type                     = "ingress"
  security_group_id        = aws_security_group.app_sg[0].id
  source_security_group_id = aws_security_group.db_sg[0].id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  description              = "Allow DB Ingress"
}

resource "aws_security_group_rule" "allow_all_egress_from_app" {
  count             = var.config.create_app_security_group ? 1 : 0
  type              = "egress"
  security_group_id = aws_security_group.app_sg[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  description       = "Allow All Traffic to Internet"
}

resource "aws_security_group_rule" "allow_openvpn_ingress_to_app" {
  count                    = (var.config.create_app_security_group && var.config.create_vpn_security_group) ? 1 : 0
  type                     = "ingress"
  depends_on               = [aws_security_group.openvpn_sg, aws_security_group.app_sg]
  security_group_id        = aws_security_group.app_sg[0].id
  source_security_group_id = aws_security_group.openvpn_sg[0].id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  description              = "Allow All Traffic from OpenVPN"
}

resource "aws_security_group_rule" "app_custom_ingress" {
  count             = var.create_app_custom_ingress ? length(var.app_custom_ingress_rules) : 0
  type              = "ingress"
  security_group_id = aws_security_group.app_sg[0].id
  protocol          = var.app_custom_ingress_rules[count.index].ip_protocol
  from_port         = var.app_custom_ingress_rules[count.index].from_port
  to_port           = var.app_custom_ingress_rules[count.index].to_port
  cidr_blocks       = [var.app_custom_ingress_rules[count.index].cidr_ipv4]
  description       = var.app_custom_ingress_rules[count.index].description
}

resource "aws_security_group_rule" "app_custom_egress" {
  count             = var.create_app_custom_egress ? length(var.app_custom_egress_rules) : 0
  type              = "egress"
  security_group_id = aws_security_group.app_sg[0].id
  from_port         = var.app_custom_egress_rules[count.index].from_port
  to_port           = var.app_custom_egress_rules[count.index].to_port
  protocol          = var.app_custom_egress_rules[count.index].ip_protocol
  cidr_blocks       = [var.app_custom_egress_rules[count.index].cidr_ipv4]
  description       = var.app_custom_egress_rules[count.index].description
}


#========================================================================================#
#                               DATABASE SG RESOURCES                                  #
#========================================================================================#

resource "aws_security_group" "db_sg" {
  count       = var.config.create_db_security_group ? 1 : 0
  name        = "${var.customer_name}-${var.environment_name}-db-sg"
  vpc_id      = var.vpc_id
  description = "Database Security Group"
  tags = merge(local.tags, {
    Name = "${var.customer_name}-${var.environment_name}-db-sg"
  })
}

resource "aws_security_group_rule" "allow_app_ingress_to_db" {
  count                    = var.config.create_db_security_group && var.config.create_app_security_group ? 1 : 0
  type                     = "ingress"
  security_group_id        = aws_security_group.db_sg[0].id
  source_security_group_id = aws_security_group.app_sg[0].id
  from_port                = var.database_port
  to_port                  = var.database_port
  protocol                 = "tcp"
  description              = "Allow traffic from Application to Database port"
}

resource "aws_security_group_rule" "allow_app_ingress_to_redis" {
  count                    = var.config.create_db_security_group && var.config.create_app_security_group ? 1 : 0
  type                     = "ingress"
  security_group_id        = aws_security_group.db_sg[0].id
  source_security_group_id = aws_security_group.app_sg[0].id
  from_port                = var.redis_port
  to_port                  = var.redis_port
  protocol                 = "tcp"
  description              = "Allow traffic from Application to Redis port"
}

resource "aws_security_group_rule" "allow_db_egress_to_app" {
  count                    = var.config.create_db_security_group && var.config.create_app_security_group ? 1 : 0
  type                     = "egress"
  security_group_id        = aws_security_group.db_sg[0].id
  source_security_group_id = aws_security_group.app_sg[0].id
  from_port                = var.database_port
  protocol                 = "tcp"
  to_port                  = var.database_port
  description              = "Allow Database Port to Application"
}

resource "aws_security_group_rule" "allow_redis_egress_to_app" {
  count                    = var.config.create_db_security_group && var.config.create_app_security_group ? 1 : 0
  type                     = "egress"
  security_group_id        = aws_security_group.db_sg[0].id
  source_security_group_id = aws_security_group.app_sg[0].id
  from_port                = var.redis_port
  protocol                 = "tcp"
  to_port                  = var.redis_port
  description              = "Allow Redis Port to Application"
}

resource "aws_security_group_rule" "allow_vpn_ingress_to_db" {
  count                    = var.config.create_db_security_group && var.config.create_vpn_security_group ? 1 : 0
  type                     = "ingress"
  security_group_id        = aws_security_group.db_sg[0].id
  source_security_group_id = aws_security_group.openvpn_sg[0].id
  from_port                = var.database_port
  to_port                  = var.database_port
  protocol                 = "tcp"
  description              = "Allow traffic from VPN to Database port"
}

resource "aws_security_group_rule" "allow_db_egress_to_vpn" {
  count                    = var.config.create_db_security_group && var.config.create_vpn_security_group ? 1 : 0
  type                     = "egress"
  security_group_id        = aws_security_group.db_sg[0].id
  source_security_group_id = aws_security_group.openvpn_sg[0].id
  from_port                = var.database_port
  protocol                 = "tcp"
  to_port                  = var.database_port
  description              = "Allow Database Port to VPN"
}

resource "aws_security_group_rule" "db_custom_ingress" {
  count             = var.create_db_custom_ingress ? length(var.db_custom_ingress_rules) : 0
  type              = "ingress"
  security_group_id = aws_security_group.db_sg[0].id
  protocol          = var.db_custom_ingress_rules[count.index].ip_protocol
  from_port         = var.db_custom_ingress_rules[count.index].from_port
  to_port           = var.db_custom_ingress_rules[count.index].to_port
  cidr_blocks       = [var.db_custom_ingress_rules[count.index].cidr_ipv4]
  description       = var.db_custom_ingress_rules[count.index].description
}

resource "aws_security_group_rule" "db_custom_egress" {
  count             = var.create_db_custom_egress ? length(var.db_custom_egress_rules) : 0
  type              = "egress"
  security_group_id = aws_security_group.db_sg[0].id
  protocol          = var.db_custom_egress_rules[count.index].ip_protocol
  from_port         = var.db_custom_egress_rules[count.index].from_port
  to_port           = var.db_custom_egress_rules[count.index].to_port
  cidr_blocks       = [var.db_custom_egress_rules[count.index].cidr_ipv4]
  description       = var.db_custom_egress_rules[count.index].description
}

#========================================================================================#
#                           ELASTIC FILE SYSTEM SG RESOURCES                             #
#========================================================================================#

resource "aws_security_group" "efs_sg" {
  count       = var.config.create_efs_security_group ? 1 : 0
  name        = "${var.customer_name}-${var.environment_name}-efs-sg"
  vpc_id      = var.vpc_id
  description = "EFS Security Group"
  tags = merge(local.tags, {
    Name = "${var.customer_name}-${var.environment_name}-efs-sg"
  })
}

resource "aws_security_group_rule" "allow_app_ingress_to_efs" {
  count                    = var.config.create_efs_security_group && var.config.create_app_security_group ? 1 : 0
  type                     = "ingress"
  security_group_id        = aws_security_group.efs_sg[0].id
  source_security_group_id = aws_security_group.app_sg[0].id
  from_port                = 2049
  protocol                 = "tcp"
  to_port                  = 2049
  description              = "Allow Application Ingress"
}

resource "aws_security_group_rule" "allow_efs_egress_to_app" {
  count                    = var.config.create_efs_security_group && var.config.create_app_security_group ? 1 : 0
  type                     = "egress"
  security_group_id        = aws_security_group.efs_sg[0].id
  source_security_group_id = aws_security_group.app_sg[0].id
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  description              = "Allow EFS port to App SG"
}

resource "aws_security_group_rule" "efs_custom_ingress" {
  count             = var.create_efs_custom_ingress ? length(var.efs_custom_ingress_rules) : 0
  type              = "ingress"
  security_group_id = aws_security_group.efs_sg[0].id
  protocol          = var.efs_custom_ingress_rules[count.index].ip_protocol
  from_port         = var.efs_custom_ingress_rules[count.index].from_port
  to_port           = var.efs_custom_ingress_rules[count.index].to_port
  cidr_blocks       = [var.efs_custom_ingress_rules[count.index].cidr_ipv4]
  description       = var.efs_custom_ingress_rules[count.index].description
}

resource "aws_security_group_rule" "efs_custom_egress" {
  count             = var.create_efs_custom_egress ? length(var.efs_custom_egress_rules) : 0
  type              = "egress"
  security_group_id = aws_security_group.efs_sg[0].id
  from_port         = var.efs_custom_egress_rules[count.index].from_port
  to_port           = var.efs_custom_egress_rules[count.index].to_port
  protocol          = var.efs_custom_egress_rules[count.index].ip_protocol
  cidr_blocks       = [var.efs_custom_egress_rules[count.index].cidr_ipv4]
  description       = var.efs_custom_egress_rules[count.index].description
}


#========================================================================================#
#                               OPENVPN SG RESOURCES                                     #
#========================================================================================#

resource "aws_security_group" "openvpn_sg" {
  count       = var.config.create_vpn_security_group ? 1 : 0
  name        = "${var.customer_name}-${var.environment_name}-vpn-sg"
  vpc_id      = var.vpc_id
  description = "OpenVPN Security Group"

  tags = merge(local.tags, {
    Name = "${var.customer_name}-${var.environment_name}-vpn-sg"
  })
}

resource "aws_security_group_rule" "allow_8080_tcp_ingress_to_vpn" {
  count             = var.config.create_vpn_security_group ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.openvpn_sg[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 8080
  protocol          = "tcp"
  to_port           = 8080
  description       = "Allow all-traffic from Internet to HTTP port"
}

resource "aws_security_group_rule" "allow_1194_udp_ingress_to_vpn" {
  count             = var.config.create_vpn_security_group ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.openvpn_sg[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 1194
  to_port           = 1194
  protocol          = "udp"
  description       = "Allow OpenVPN (UDP 1194)"
}

resource "aws_security_group_rule" "allow_all_egress_from_vpn" {
  count             = var.config.create_vpn_security_group ? 1 : 0
  type              = "egress"
  security_group_id = aws_security_group.openvpn_sg[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  description       = "Allow All Traffic to internet"
}

resource "aws_security_group_rule" "openvpn_custom_ingress" {
  count             = var.create_openvpn_custom_ingress ? length(var.openvpn_custom_ingress_rules) : 0
  type              = "ingress"
  security_group_id = aws_security_group.openvpn_sg[0].id
  protocol          = var.openvpn_custom_ingress_rules[count.index].ip_protocol
  from_port         = var.openvpn_custom_ingress_rules[count.index].from_port
  to_port           = var.openvpn_custom_ingress_rules[count.index].to_port
  cidr_blocks       = [var.openvpn_custom_ingress_rules[count.index].cidr_ipv4]
  description       = var.openvpn_custom_ingress_rules[count.index].description
}

resource "aws_security_group_rule" "openvpn_custom_egress" {
  count             = var.create_openvpn_custom_egress ? length(var.openvpn_custom_egress_rules) : 0
  type              = "egress"
  security_group_id = aws_security_group.openvpn_sg[0].id
  protocol          = var.openvpn_custom_egress_rules[count.index].ip_protocol
  from_port         = var.openvpn_custom_egress_rules[count.index].from_port
  to_port           = var.openvpn_custom_egress_rules[count.index].to_port
  cidr_blocks       = [var.openvpn_custom_egress_rules[count.index].cidr_ipv4]
  description       = var.openvpn_custom_egress_rules[count.index].description
}

resource "aws_security_group_rule" "allow_alb_ingress_to_vpn" {
  count                    = (var.config.create_vpn_security_group && var.config.create_alb_security_group) ? 1 : 0
  type                     = "ingress"
  depends_on               = [aws_security_group.alb_sg, aws_security_group.openvpn_sg]
  security_group_id        = aws_security_group.openvpn_sg[0].id
  source_security_group_id = aws_security_group.alb_sg[0].id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  description              = "Allow ALB Ingress"
}

resource "aws_security_group_rule" "allow_nlb_ingress_to_vpn" {
  count                    = (var.config.create_vpn_security_group && var.config.create_nlb_security_group) ? 1 : 0
  type                     = "ingress"
  depends_on               = [aws_security_group.nlb_sg, aws_security_group.openvpn_sg]
  security_group_id        = aws_security_group.openvpn_sg[0].id
  source_security_group_id = aws_security_group.nlb_sg[0].id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  description              = "Allow NLB Ingress"
}


#========================================================================================#
#                             ADMIN PREFIX LIST RESOURCES                                #
#========================================================================================#

resource "aws_ec2_managed_prefix_list" "admins" {
  name           = "${var.customer_name}-${var.environment_name}-prefix-list"
  address_family = "IPv4"
  max_entries    = 5

  dynamic "entry" {
    for_each = var.admin_ips

    content {
      cidr        = entry.value.ip
      description = entry.value.description
    }
  }

  tags = var.tags
}

resource "aws_security_group_rule" "allow_admins_inbound_ssh" {
  count             = var.config.create_vpn_security_group ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.openvpn_sg[0].id
  prefix_list_ids   = [aws_ec2_managed_prefix_list.admins.id]
  from_port         = 22
  protocol          = "tcp"
  to_port           = 22
  description       = "Allow SSH from Admins Prefix List"
}

resource "aws_security_group_rule" "allow_admins_outbound_all" {
  count             = var.config.create_vpn_security_group ? 1 : 0
  type              = "egress"
  security_group_id = aws_security_group.openvpn_sg[0].id
  prefix_list_ids   = [aws_ec2_managed_prefix_list.admins.id]
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  description       = "Allow All Traffic to Admins Prefix List"
}
