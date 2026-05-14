resource "aws_backup_vault" "vault" {
  name        = "${var.customer-name}-${var.environment_name}-vault"
  kms_key_arn = var.kms_key_arn

  tags = merge(local.tags, {})
}

resource "aws_backup_plan" "plan" {
  name = "${var.customer-name}-${var.environment_name}-backup-plan"

  dynamic "rule" {
    for_each = var.enable_daily_backup ? [1] : []
    content {
      rule_name         = "${var.customer-name}-${var.environment_name}-daily-rule"
      target_vault_name = aws_backup_vault.vault.name
      schedule          = var.backup_schedule_daily

      lifecycle {
        delete_after = var.delete_after_days_daily
      }
    }
  }

  dynamic "rule" {
    for_each = var.enable_weekly_backup ? [1] : []
    content {
      rule_name         = "${var.customer-name}-${var.environment_name}-weekly-rule"
      target_vault_name = aws_backup_vault.vault.name
      schedule          = var.backup_schedule_weekly

      lifecycle {
        delete_after = var.delete_after_days_weekly
      }
    }
  }

  dynamic "rule" {
    for_each = var.enable_monthly_backup ? [1] : []
    content {
      rule_name         = "${var.customer-name}-${var.environment_name}-monthly-rule"
      target_vault_name = aws_backup_vault.vault.name
      schedule          = var.backup_schedule_monthly

      lifecycle {
        delete_after = var.delete_after_days_monthly
      }
    }
  }

  tags = merge(local.tags, {})
}

resource "aws_backup_selection" "backup_selection" {
  name         = "${var.customer-name}-${var.environment_name}-backup-selection"
  iam_role_arn = aws_iam_role.role.arn
  plan_id      = aws_backup_plan.plan.id

  dynamic "selection_tag" {
    for_each = var.enable_daily_backup ? [1] : []
    content {

      type  = "STRINGEQUALS"
      key   = "Daily-Backup"
      value = "True"
    }
  }
  dynamic "selection_tag" {
    for_each = var.enable_weekly_backup ? [1] : []
    content {
      type  = "STRINGEQUALS"
      key   = "Weekly-Backup"
      value = "True"
    }
  }
  dynamic "selection_tag" {
    for_each = var.enable_monthly_backup ? [1] : []
    content {
      type  = "STRINGEQUALS"
      key   = "Monthly-Backup"
      value = "True"
    }
  }
}

resource "aws_iam_role" "role" {
  name = "${var.customer-name}-${var.environment_name}-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "backup.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })

  tags = merge(local.tags, {})
}

resource "aws_iam_role_policy_attachment" "role_policy" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

