resource "aws_lb" "alb" {
  name               = local.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.alb_security_group_id
  subnets            = var.alb_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  access_logs {
    bucket  = var.enable_alb_logs ? aws_s3_bucket.alb_logs_bucket[0].id : 0
    enabled = var.enable_alb_logs
  }

  tags = merge(local.tags, {})
}

resource "aws_lb_listener" "https_listener" {
  depends_on = [aws_lb.alb]
  count      = local.create_https_listerner ? 1 : 0

  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = local.has_custom_ssl_policy ? var.alb_custom_ssl_policy : "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arns[0]

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Nothing here"
      status_code  = "404"
    }
  }

  timeouts {
    create = "2m"
    update = "2m"
  }

  tags = merge(local.tags, {})
}

resource "aws_lb_listener_certificate" "additional_certs" {
  count           = length(var.certificate_arns) > 1 ? length(var.certificate_arns) - 1 : 0
  listener_arn    = aws_lb_listener.https_listener[0].arn
  certificate_arn = var.certificate_arns[count.index + 1]
}

resource "aws_lb_listener" "http_listener" {
  depends_on = [aws_lb.alb]

  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  timeouts {
    create = "1m"
    update = "1m"
  }

  tags = merge(local.tags, {})
}

resource "random_pet" "alb" {
  prefix    = "logs"
  separator = "-"
}

resource "aws_lb_target_group" "alb_target_group" {
  name     = "${var.customer_name}-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags = merge(local.tags, {})
}

resource "aws_lb_target_group_attachment" "target_group_attachment" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = var.instance_id
}


resource "aws_lb_listener_rule" "app" {
  listener_arn = aws_lb_listener.https_listener[0].arn
  priority     = 10

  condition {
    host_header {
      values = [var.host_header]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }

  tags = merge(local.tags, {})
}

# OPENVPN TARGET GROUP AND LISTENER RULE

resource "aws_lb_target_group" "openvpn_tg" {
  name     = "${var.customer_name}-${var.environment}-openvpn-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags = merge(local.tags, {})
}

resource "aws_lb_target_group_attachment" "openvpn_attachment" {
  target_group_arn = aws_lb_target_group.openvpn_tg.arn
  target_id        = var.openvpn_instance_id
}

resource "aws_lb_listener_rule" "openvpn_listener" {
  listener_arn = aws_lb_listener.https_listener[0].arn
  priority     = 20

  condition {
    host_header {
      values = [var.openvpn_host_header]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.openvpn_tg.arn
  }

  tags = merge(local.tags, {})
}

###############################################################
#                 Create Access Log Bucket                    #
###############################################################
resource "aws_s3_bucket" "alb_logs_bucket" {
  depends_on = [random_pet.alb]
  count      = local.create_access_logs ? 1 : 0
  bucket     = "${lower(local.alb_name)}-${random_pet.alb.id}"

  force_destroy = true

  tags = merge(local.tags, {})
}

resource "aws_s3_bucket_policy" "attachment_policy" {
  depends_on = [aws_s3_bucket.alb_logs_bucket]
  count      = local.create_access_logs ? 1 : 0
  bucket     = aws_s3_bucket.alb_logs_bucket[0].id
  policy     = data.aws_iam_policy_document.alb_logs_bucket_policy[0].json
}

data "aws_iam_policy_document" "alb_logs_bucket_policy" {
  depends_on = [aws_s3_bucket.alb_logs_bucket]
  count      = local.create_access_logs ? 1 : 0
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${lookup(local.alb_logs_id, local.alb_region)}:root"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      aws_s3_bucket.alb_logs_bucket[0].arn,
      "${aws_s3_bucket.alb_logs_bucket[0].arn}/*",
    ]
  }
}