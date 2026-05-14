variable "aws_region" {
  type = string
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
  type = map(string)
}

################## ALARME CW ##########################

variable "customer_name" {
  type = string
}

variable "cloudwatch_subscriptions" {
  description = "Map of subscription configurations"
  type = map(object({
    protocol = string
    endpoint = string
  }))
  validation {
    condition     = alltrue([for s in var.cloudwatch_subscriptions : contains(["email", "https"], s.protocol)])
    error_message = "Protocol must be either 'email' or 'https'."
  }
}

variable "create_dashboard" {
  type    = bool
  default = true
}
