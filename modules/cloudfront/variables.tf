#========================================================================================#
#                                 CUSTOMER VARIABLES                                     #
#========================================================================================#
variable "customer_name" {
  description = "Nome do Cliente"
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

#========================================================================================#
#                                 DISTRIBUTION VARIABLES                                 #
#========================================================================================#

variable "domain_name" {
  description = "Nome do domínio que será utilizado no CloudFront. É necessário que esse domínio seja criado no ACM"
  type        = string
}

variable "alb_id" {
  description = "ID do Application Load Balancer que será utilizado como origem do CloudFront"
  type        = string
}

variable "certificate_arn" {
  description = "ARN do certificado do ACM"
  type        = string
}

