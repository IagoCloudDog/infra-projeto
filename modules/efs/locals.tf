locals {
  effective_backup_policy = var.create_backup_policy ? var.enable_backup_policy : false
}

locals {
  tags = var.tags
}