#================================================= CUSTOMER VARIABLES ==============================================
variable "customer-name" {
  description = "Nome do cliente que utilizará o Backup"
  type        = string
}

variable "environment_name" {
  type        = string
  description = "Nome do ambiente em que o Backup será provisionado. Valores permitidos: [prd | stg | qa | dev | labs | payer | devops]"
  validation {
    condition     = contains(["prd", "stg", "qa", "dev", "labs", "payer", "devops"], var.environment_name)
    error_message = "O valor deve ser 'prd', 'stg', 'qa', 'dev' ou 'labs'."
  }
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources"
}

#============================================= AWS BACKUP VARIABLES ================================================
variable "kms_key_arn" {
  description = "KMS Key ARN para criptografia (opcional)"
  type        = string
  default     = ""
}

#================================================= ENABLE VARIABLES ==============================================

variable "enable_daily_backup" {
  description = "Ativar backup diário"
  type        = bool
}

variable "enable_weekly_backup" {
  description = "Ativar backup semanal"
  type        = bool
}

variable "enable_monthly_backup" {
  description = "Ativar backup mensal"
  type        = bool
}

#================================================= DELETE VARIABLES ==============================================

variable "delete_after_days_daily" {
  description = "Tempo de delete do plano diario"
  type        = string
  default     = "7"
}

variable "delete_after_days_weekly" {
  description = "Tempo de delete do plano semanal"
  type        = string
  default     = "30"
}

variable "delete_after_days_monthly" {
  description = "Tempo de delete do plano mensal "
  type        = string
  default     = "365"
}

#================================================= SCHEDULE VARIABLES ==============================================

variable "backup_schedule_daily" {
  description = "Agendamento diário de backup (default: todo dia às 3:00 UTC) "
  type        = string
  default     = "cron(0 3 * * ? *)"
}

variable "backup_schedule_weekly" {
  description = "Agendamento semanal de backup (default: todo domingo às 3:00 UTC)"
  type        = string
  default     = "cron(0 3 ? * 7 *)"
}

variable "backup_schedule_monthly" {
  description = "Agendamento mensal de backup (default: todo dia 1 às 3:00 UTC)"
  type        = string
  default     = "cron(0 3 1 * ? *)"
}
