variable "customer_name" {
  description = "Name of the customer this Redis cluster belongs to"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "elastic_cache_type" {
  description = "value"
  type        = string
  validation {
    condition     = contains(["redis", "valkey", "memcached"], lower(var.elastic_cache_type))
    error_message = "The value must be either 'redis', 'memcached', 'valkey'."
  }
}

variable "data_subnet_ids" {
  description = "List of subnet data IDs where Redis will be deployed"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to Redis"
  type        = list(string)
}

variable "engine_version" {
  description = "Cache engine version"
  type        = string
  default     = "7.0"
}

variable "encryption" {
  description = "Encryption configuration"
  type = object({
    at_rest = bool
    transit = bool
  })
  default = {
    at_rest = true
    transit = false
  }
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "compute_configuration" {
  description = "Configuration for standard Redis deployment"
  type = object({
    enabled                 = bool
    node_type               = string
    num_node_groups         = number
    replicas_per_node_group = number
    automatic_failover      = bool
    multi_az                = bool
  })
  default = {
    enabled                 = false
    node_type               = "cache.t3.micro"
    num_node_groups         = 1
    replicas_per_node_group = 1
    automatic_failover      = false
    multi_az                = false
  }
}


variable "serverless_configuration" {
  description = "Configuration for serverless Memcached deployment"
  type = object({
    enabled = bool
    usage_limits = object({
      data_storage = object({
        maximum = number
        unit    = string
      })
      ecpu = object({
        maximum = number
      })
    })
  })
  default = {
    enabled = false
    usage_limits = {
      data_storage = {
        maximum = 50
        unit    = "GB"
      }
      ecpu = {
        maximum = 1000
      }
    }
  }
}