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

variable "region" {
  description = "Região em que a EC2 será provisionada"
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources"
}

#========================================================================================#
#                                 INSTANCE VARIABLES                                     #
#========================================================================================#

variable "subnet_id" {
  description = "O ID da Subnet que a EC2 será provisionaada"
  type        = string
}

variable "security_group_id" {
  description = "O ID do Security Group que estará associado à EC2"
  type        = string
}

variable "instance_type" {
  description = "O tipo de instância que será provisionada. Ex: 't2.micro'"
  type        = string
}

variable "volume_type" {
  description = "O tipo de volume que será provisionado (opcional). Valores permitidos: [gp3 | gp2 | io1 | io2 | sc1 | st1]"
  type        = string
  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2", "sc1", "st1"], var.volume_type)
    error_message = "O valor deve ser 'gp3', 'gp2', 'io1', 'io2', 'sc1' ou 'st1'."
  }
  default = "gp3"
}

variable "volume_size" {
  description = "O tamanho do volume que será provisionado (opcional)."
  type        = number
  default     = 30
}

variable "os_arch" {
  description = "Arquitetura do Sistema Operacional que será instalado na EC2. Valores permitidos: [debian_arm64 | debian_amd64 | ubuntu_arm64 |ubuntu_amd64 | winserver2022 | winserver2019]"
  type        = string
  validation {
    condition     = contains(["graviton", "x86"], var.os_arch)
    error_message = "O valor deve ser 'x86', 'graviton'."
  }
}

variable "public_ip" {
  description = "Decide se criará ou não um IP Público"
  type        = bool
  default     = true
}

variable "db_host" {
  description = "Endpoint do RDS"
  type        = string
}

variable "db_user" {
  description = "Usuário do RDS"
  type        = string
}

variable "secrets_arn" {
  type = string
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
}

variable "php_version" {
  description = "Versão do PHP que será instalada na EC2"
  type        = string
}

variable "enable_sftp" {
  description = "Decide se o SFTP será criado ou não."
  type        = bool
}

variable "app_domain" {
  type        = string
  description = "Dominio da aplicação"
}

variable "efs_id" {
  type        = string
  description = "ID do EFS"
}

variable "redis_host" {
  type        = string
  description = "Host do Redis"
}
variable "cloudfront_domain" {
  type        = string
  description = "URL do cloudfront"
}
variable "daily_backup" {
  description = "Decide se o backup será diário ou não"
  type        = string
}

variable "weekly_backup" {
  description = "Decide se o backup será semanal ou não"
  type        = string
}
variable "monthly_backup" {
  description = "Decide se o backup será mensal ou não"
  type        = string
}