variable "customer_name" {
  type        = string
  description = "Nome do cliente, usado para nomear recursos como o ALB."
}

variable "certificate_arns" {
  type        = list(string)
  default     = []
  description = "Lista de ARNs de certificados ACM para o listener HTTPS do ALB."
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Habilita ou desabilita a proteção contra exclusão do ALB."
}

variable "alb_custom_ssl_policy" {
  type        = string
  default     = ""
  description = "Política SSL personalizada para o listener HTTPS do ALB. Ex: ELBSecurityPolicy-TLS-1-2-2017-01."
}

variable "alb_security_group_id" {
  type        = list(string)
  description = "Lista de IDs de Security Groups para associar ao ALB."
}

variable "tags" {
  type        = map(string)
  description = "Mapa de tags aplicadas a todos os recursos criados."
}

variable "alb_subnet_ids" {
  type        = list(string)
  description = "Lista de IDs de subnets nas quais o ALB será provisionado."
}

variable "environment" {
  type        = string
  description = "Ambiente de implantação (ex: dev, stg, prd)."
}

variable "enable_alb_logs" {
  type        = bool
  default     = false
  description = "Habilita ou desabilita os logs de acesso do ALB para o S3."
}

variable "vpc_id" {
  type = string
}

variable "instance_id" {
  type = string
}

variable "host_header" {
  type = string
}

variable "openvpn_instance_id" {
  type = string
}

variable "openvpn_host_header" {
  type = string
}