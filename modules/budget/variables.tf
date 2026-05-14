#========================================================================================#
#                                CUSTOMER VARIABLES                                      #
#========================================================================================#

variable "customer_name" {
  description = "Nome do cliente que utilizará o AWS Budget"
  type        = string
}

variable "monthly_budget_value" {
  description = "Valor limite do orçamento mensal"
  type        = string
}

variable "daily_budget_value" {
  description = "Valor limite do orçamento diário"
  type        = string
}

variable "budget_subscriptions" {
  description = "Map of subscription configurations"
  type = map(object({
    protocol = string
    endpoint = string
  }))
  validation {
    condition     = alltrue([for s in var.budget_subscriptions : contains(["email", "https"], s.protocol)])
    error_message = "Protocol must be either 'email' or 'https'."
  }
}

variable "budget_filter_tag" {
  description = "Chave da tag para filtrar o orçamento. (Ex: Project)"
  type        = string
}

variable "budget_filter_value" {
  description = "Valor da tag para filtrar o orçamento. (Ex: Migration)"
  type        = string
}

variable "environment_name" {
  type        = string
  description = "Nome do ambiente. Valores permitidos: [prd | stg | qa | dev | devops | labs | payer]"
  validation {
    condition     = contains(["prd", "stg", "qa", "dev", "devops", "labs", "payer"], var.environment_name)
    error_message = "The value must be either 'prd', 'stg', 'qa', 'dev', 'devops', 'labs', 'payer'."
  }
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources"
}