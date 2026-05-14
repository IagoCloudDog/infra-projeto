#========================================================================================#
#                                CUSTOMER VARIABLES                                      #
#========================================================================================#

variable "customer_name" {
  description = "Nome do cliente que utilizará o recurso"
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

#========================================================================================#
#                                   SG VARIABLES                                         #
#========================================================================================#

# Config block to choose which security groups to create
variable "config" {
  description = "Decide quais Security Groups serão criados"
  type = object({
    create_efs_security_group = bool
    create_app_security_group = bool
    create_db_security_group  = bool
    create_alb_security_group = bool
    create_vpn_security_group = bool
    create_nlb_security_group = bool
  })
}

variable "admin_ips" {
  type = list(object({
    ip          = string
    description = string
  }))
}

variable "vpc_id" {
  type        = string
  description = "ID da VPC"
}

variable "tags" {
  type        = map(string)
  description = "Mapa de tags"
}

variable "database_port" {
  description = "Porta do banco de dados"
  type        = number
}

variable "redis_port" {
  description = "Porta do banco de dados redis"
  type        = number
}

# Custom ingress/egress rules for application security group
variable "create_app_custom_ingress" {
  description = "Decide se criará ou não uma regra de ingress personalizada"
  type        = bool
  default     = false
}

variable "create_app_custom_egress" {
  description = "Decide se criará ou não uma regra de egress personalizada"
  type        = bool
  default     = false
}

variable "app_custom_ingress_rules" {
  type = list(object({
    cidr_ipv4   = string
    ip_protocol = string
    from_port   = number
    to_port     = number
    description = string
  }))
  default = []
}

variable "app_custom_egress_rules" {
  type = list(object({
    cidr_ipv4   = string
    ip_protocol = string
    from_port   = number
    to_port     = number
    description = string
  }))
  default = []
}

# Custom ingress/egress rules for database security group

variable "create_db_custom_ingress" {
  description = "Decide se criará ou não uma regra de ingress personalizada"
  type        = bool
  default     = false
}

variable "create_db_custom_egress" {
  description = "Decide se criará ou não uma regra de egress personalizada"
  type        = bool
  default     = false
}

variable "db_custom_ingress_rules" {
  type = list(object({
    cidr_ipv4   = string
    ip_protocol = string
    from_port   = number
    to_port     = number
    description = string
  }))
  default = []
}

variable "db_custom_egress_rules" {
  type = list(object({
    cidr_ipv4   = string
    ip_protocol = string
    from_port   = number
    to_port     = number
    description = string
  }))
  default = []
}

# Custom ingress/egress rules for elastic file system security group

variable "create_efs_custom_ingress" {
  description = "Decide se criará ou não uma regra de ingress personalizada"
  type        = bool
  default     = false
}

variable "create_efs_custom_egress" {
  description = "Decide se criará ou não uma regra de egress personalizada"
  type        = bool
  default     = false
}

variable "efs_custom_ingress_rules" {
  type = list(object({
    cidr_ipv4   = string
    ip_protocol = string
    from_port   = number
    to_port     = number
    description = string
  }))
  default = []
}

variable "efs_custom_egress_rules" {
  type = list(object({
    cidr_ipv4   = string
    ip_protocol = string
    from_port   = number
    to_port     = number
    description = string
  }))
  default = []
}

# Custom ingress/egress rules for openvpn system security group

variable "create_openvpn_custom_ingress" {
  description = "Decide se criará ou não uma regra de ingress personalizada"
  type        = bool
  default     = false
}

variable "create_openvpn_custom_egress" {
  description = "Decide se criará ou não uma regra de egress personalizada"
  type        = bool
  default     = false
}

variable "openvpn_custom_ingress_rules" {
  type = list(object({
    cidr_ipv4   = string
    ip_protocol = string
    from_port   = number
    to_port     = number
    description = string
  }))
  default = []
}

variable "openvpn_custom_egress_rules" {
  type = list(object({
    cidr_ipv4   = string
    ip_protocol = string
    from_port   = number
    to_port     = number
    description = string
  }))
  default = []
}