#========================================================================================#
#                                CUSTOMER VARIABLES                                      #
#========================================================================================#

variable "customer_name" {
  description = "Nome do cliente que utilizará o AWS Budget"
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
#                                LAUNCH TEMPLATE VARIABLES                               #
#========================================================================================#

variable "ec2_instance_id" {
  description = "ID da instância EC2 que será utilizada para criar o Launch Template"
  type        = string
}

variable "lt_instance_type" {
  description = "Tipo de instância que o Launch Template utilizará"
  type        = string
}

variable "ec2_iam_instance_profile_arn" {
  type = string
}

variable "ec2_security_group_id" {
  type = string
}

#========================================================================================#
#                               AUTO SCALING GROUP VARIABLES                             #
#========================================================================================#

variable "enable_asg" {
  description = "Decide se o autoscaling será criado ou não"
  type        = bool
}

variable "instances_desired_capacity" {
  description = "Capacidade desejada de instâncias do Auto Scaling Group"
  type        = number
}

variable "instances_min_size" {
  description = "Quantidade mínima de instâncias do Auto Scaling Group"
  type        = number
}

variable "instances_max_size" {
  description = "Quantidade máxima de instâncias do Auto Scaling Group"
  type        = number
}

variable "on_demand_health_check_type" {
  description = "Tipo de health check que será utilizado"
  type        = string
  default     = "ELB"
}

variable "target_group_arns" {
  description = "Target Groups que serão ligados ao ASG"
  type        = set(string)
}

variable "health_check_grace_period" {
  description = "Tempo (em segundos) após uma instância entrar em serviço antes do health check"
  type        = number
  default     = 300
}

variable "vpc_zone_identifier" {
  description = "Lista de subnets em que o Auto Scaling Group pertencerá"
  type        = list(string)
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

#========================================================================================#
#                              AUTO SCALING POLICY VARIABLES                             #
#========================================================================================#

variable "enable_cpu_scaling" {
  description = "Decide se o Auto Scaling deve ser de CPU ou não"
  type        = bool
  default     = true
}

variable "enable_network_scaling" {
  description = "Decide se o Auto Scaling deve ser de memória ou não"
  type        = bool
  default     = false
}

variable "scale_config_warmup" {
  description = "Tempo (em segundos) até que uma instância recém-iniciada esteja de fato pronta para ser escalada"
  type        = number
  default     = 120
}

variable "cpu_target_value" {
  type    = number
  default = 80
}

variable "alb_target_value" {
  type    = number
  default = 2000
}

variable "alb_target_group_arn_suffix" {
  description = "ARN Suffix do Target Group do ALB"
  type        = string
}

variable "alb_load_balancer_arn_suffix" {
  description = "ARN Suffix do ALB"
  type        = string
}