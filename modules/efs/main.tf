#==============================================================================#
#                             FILE SYSTEM RESOURCE                             # 
#==============================================================================#

resource "aws_efs_file_system" "efs" {
  count = var.create ? 1 : 0

  availability_zone_name          = var.availability_zone_name
  creation_token                  = "${var.customer_name}-wordpress-${var.environment_name}-efs"
  performance_mode                = var.performance_mode
  encrypted                       = var.encrypted
  kms_key_id                      = var.kms_key_arn
  provisioned_throughput_in_mibps = var.provisioned_throughput_in_mibps
  throughput_mode                 = var.throughput_mode

  tags = merge(local.tags, {
    Name = "${var.customer_name}-wordpress-${var.environment_name}-efs"
  })
}

#==============================================================================#
#                             FILE SYSTEM POLICY                               # 
#==============================================================================#

data "aws_iam_policy_document" "policy" {
  count = var.create && var.attach_policy ? 1 : 0

  source_policy_documents   = var.source_policy_documents
  override_policy_documents = var.override_policy_documents

  dynamic "statement" {
    for_each = var.policy_statements

    content {
      sid           = try(statement.value.sid, null)
      actions       = try(statement.value.actions, null)
      not_actions   = try(statement.value.not_actions, null)
      effect        = try(statement.value.effect, null)
      resources     = try(statement.value.resources, [aws_efs_file_system.efs[0].arn], null)
      not_resources = try(statement.value.not_resources, null)

      dynamic "principals" {
        for_each = try(statement.value.principals, [])

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = try(statement.value.not_principals, [])

        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = try(statement.value.conditions, statement.value.condition, [])

        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }

  dynamic "statement" {
    for_each = var.deny_nonsecure_transport ? [1] : []

    content {
      sid       = "NonSecureTransport"
      effect    = "Deny"
      actions   = ["*"]
      resources = [aws_efs_file_system.efs[0].arn]

      principals {
        type        = "AWS"
        identifiers = ["*"]
      }

      condition {
        test     = "Bool"
        variable = "aws:SecureTransport"
        values   = ["false"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.deny_nonsecure_transport_via_mount_target ? [1] : []

    content {
      sid    = "NonSecureTransportAccessedViaMountTarget"
      effect = "Allow"
      actions = [
        "elasticfilesystem:ClientRootAccess",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:ClientMount"
      ]
      resources = [aws_efs_file_system.efs[0].arn]

      principals {
        type        = "AWS"
        identifiers = ["*"]
      }

      condition {
        test     = "Bool"
        variable = "elasticfilesystem:AccessedViaMountTarget"
        values   = ["true"]
      }
    }
  }
}

resource "aws_efs_file_system_policy" "this" {
  count = var.create && var.attach_policy ? 1 : 0

  file_system_id                     = aws_efs_file_system.efs[0].id
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check
  policy                             = data.aws_iam_policy_document.policy[0].json
}

#==============================================================================#
#                             MOUNT TARGET RESOURCE                            # 
#==============================================================================#
resource "aws_efs_mount_target" "this" {
  for_each = { for k, v in var.mount_targets : k => v if var.create }

  file_system_id  = aws_efs_file_system.efs[0].id
  ip_address      = try(each.value.ip_address, null)
  security_groups = var.security_group_efs
  subnet_id       = each.value.subnet_id
}

#==============================================================================#
#                            ACCESS POINT RESOURCE                             # 
#==============================================================================#

resource "aws_efs_access_point" "this" {
  for_each = { for k, v in var.access_points : k => v if var.create }

  file_system_id = aws_efs_file_system.efs[0].id

  dynamic "posix_user" {
    for_each = try([each.value.posix_user], [])

    content {
      gid            = posix_user.value.gid
      uid            = posix_user.value.uid
      secondary_gids = try(posix_user.value.secondary_gids, null)
    }
  }

  dynamic "root_directory" {
    for_each = try([each.value.root_directory], [])

    content {
      path = try(root_directory.value.path, null)

      dynamic "creation_info" {
        for_each = try([root_directory.value.creation_info], [])

        content {
          owner_gid   = creation_info.value.owner_gid
          owner_uid   = creation_info.value.owner_uid
          permissions = creation_info.value.permissions
        }
      }
    }
  }

  tags = merge(local.tags, {})
}

#==============================================================================#
#                               BACKUP POLICY                                  # 
#==============================================================================#

resource "aws_efs_backup_policy" "this" {
  count = var.create && var.create_backup_policy ? 1 : 0

  file_system_id = aws_efs_file_system.efs[0].id

  backup_policy {
    status = local.effective_backup_policy ? "ENABLED" : "DISABLED"
  }
}

#==============================================================================#
#                            REPLICATION RESOURCE                              # 
#==============================================================================#

resource "aws_efs_replication_configuration" "this" {
  count = var.create && var.create_replication_configuration ? 1 : 0

  source_file_system_id = aws_efs_file_system.efs[0].id

  dynamic "destination" {
    for_each = [var.replication_configuration_destination]

    content {
      availability_zone_name = try(destination.value.availability_zone_name, null)
      kms_key_id             = try(destination.value.kms_key_id, null)
      region                 = try(destination.value.region, null)
    }
  }
}