variable "customer_name" {
  type        = string
  description = "Customer Name"
}

variable "environment" {
  type        = string
  description = "Environment name. Allowed values: [prd | stg | qa | dev | labs]"
  validation {
    condition     = contains(["prd", "stg", "qa", "dev", "labs"], var.environment)
    error_message = "The value must be either 'prd', 'stg', 'qa', 'dev', 'labs'."
  }
}

variable "cluster_name" {
  description = "Nome do cluster para tagging das subnets privadas"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "enable_ipv6" {
  type        = bool
  description = "Enable ipv6 for the VPC"
  validation {
    condition     = contains([true, false], var.enable_ipv6)
    error_message = "The value must be either 'true' or 'false'."
  }
}

variable "create_data_subnets" {
  type        = bool
  description = "Creates a data subnet. Allowed values: [true | false]."
  validation {
    condition     = contains([true, false], var.create_data_subnets)
    error_message = "The value must be either 'true' or 'false'."
  }
}

variable "create_app_subnets" {
  type        = bool
  description = "Creates a private subnet. Allowed values: [true | false]."
  validation {
    condition     = contains([true, false], var.create_app_subnets)
    error_message = "The value must be either 'true' or 'false'."
  }
}

variable "create_public_subnets" {
  type        = bool
  description = "Creates a public subnet. Allowed values: [true | false]."
  validation {
    condition     = contains([true, false], var.create_public_subnets)
    error_message = "The value must be either 'true' or 'false'."
  }
}

variable "nat_gateway_high_availability" {
  type        = bool
  description = "Set to false to create just one nat gateway. If set to true it will create a nat gateway per private subnet. Allowed values: [true | false]."
  validation {
    condition     = contains([true, false], var.nat_gateway_high_availability)
    error_message = "The value must be either 'true' or 'false'."
  }
}

variable "number_of_azs" {
  type        = number
  description = "Number of Availability Zones to be used in the VPC. Allowed values: [2 | 3 | 4]."
  validation {
    condition     = contains([2, 3, 4], var.number_of_azs)
    error_message = "The value must be one of '2', '3', or '4'."
  }
}

variable "create_nat" {
  type        = bool
  description = "If false, not create NAT Gateway. Allowed values: [true | false]."
  validation {
    condition     = contains([true, false], var.create_nat)
    error_message = "The value must be either 'true' or 'false'."
  }
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources"
}
