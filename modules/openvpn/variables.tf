#========================================================================================#
#                                 CUSTOMER VARIABLES                                     #
#========================================================================================#

variable "customer_name" {
  description = "Nome do cliente"
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

variable "region" {
  type        = string
  description = "Região em que o ambiente será provisionado"
}

#========================================================================================#
#                                 INSTANCE VARIABLES                                     #
#========================================================================================#

variable "instance_type" {
  description = "Tipo de instância a ser provisionada (necessário ser graviton)."
  type        = string
}

variable "public_subnet_id" {
  description = "Subnet pública em que a OpenVPN será provisionada."
  type        = string
}

variable "security_group_id" {
  description = "Security Group da OpenVPN."
  type        = string
}

variable "volume_size" {
  description = "O tamanho do volume que será provisionado (opcional)."
  type        = number
  default     = 30
}

variable "vpc_range" {
  type = string
}