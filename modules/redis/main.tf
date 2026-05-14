##########################################################
#         Subnet Group and Parameter Group               #
##########################################################
resource "aws_elasticache_subnet_group" "subnet_group" {
  name        = "${var.customer_name}-${var.environment}-${var.elastic_cache_type}-subnet-group"
  description = "Subnet group for ${var.customer_name} ${var.elastic_cache_type} in ${var.environment}"
  subnet_ids  = var.data_subnet_ids
  tags        = merge(var.tags, { Name = "${var.customer_name}-${var.environment}-${var.elastic_cache_type}-subnet-group" })
}

resource "aws_elasticache_parameter_group" "parameter_group" {
  count = var.compute_configuration.enabled ? 1 : 0

  name        = "${var.customer_name}-${var.environment}-${var.elastic_cache_type}-pg"
  family      = "${var.elastic_cache_type}${split(".", var.engine_version)[0]}"
  description = "Custom parameter group for ${var.customer_name} ${var.elastic_cache_type} ${var.engine_version}"

  tags = merge(var.tags, { Name = "${var.customer_name}-${var.environment}-${var.elastic_cache_type}-pg" })
}

##########################################################
#         Elastic Cache for Redis or Valkey              #
##########################################################
resource "aws_elasticache_replication_group" "standard" {
  count = var.compute_configuration.enabled && (var.elastic_cache_type != "memcached") ? 1 : 0

  replication_group_id       = "${var.customer_name}-${var.environment}-${var.elastic_cache_type}"
  description                = "Standard ${var.elastic_cache_type} cluster for ${var.customer_name} in ${var.environment}"
  node_type                  = var.compute_configuration.node_type
  port                       = 6379
  parameter_group_name       = aws_elasticache_parameter_group.parameter_group.0.name
  automatic_failover_enabled = var.compute_configuration.automatic_failover
  multi_az_enabled           = var.compute_configuration.multi_az
  at_rest_encryption_enabled = var.encryption.at_rest
  transit_encryption_enabled = var.encryption.transit
  engine                     = var.elastic_cache_type
  engine_version             = var.engine_version
  num_node_groups            = var.compute_configuration.num_node_groups
  replicas_per_node_group    = var.compute_configuration.replicas_per_node_group
  subnet_group_name          = aws_elasticache_subnet_group.subnet_group.name
  security_group_ids         = var.security_group_ids
  maintenance_window         = "sun:05:00-sun:06:00"

  tags = merge(var.tags, {
    Name       = "${var.customer_name}-${var.environment}-${var.elastic_cache_type}",
    Deployment = "standard"
  })
}

##########################################################
#           Elastic Cache for Memcached                  #
##########################################################
resource "aws_elasticache_cluster" "memcached" {
  count = var.compute_configuration.enabled && var.elastic_cache_type == "memcached" ? 1 : 0

  cluster_id           = "${var.customer_name}-${var.environment}-memcached"
  engine               = "memcached"
  engine_version       = var.engine_version
  node_type            = var.compute_configuration.node_type
  num_cache_nodes      = var.compute_configuration.num_node_groups
  parameter_group_name = aws_elasticache_parameter_group.parameter_group.0.name
  port                 = 11211
  subnet_group_name    = aws_elasticache_subnet_group.subnet_group.name
  security_group_ids   = var.security_group_ids
  az_mode              = var.compute_configuration.multi_az ? "cross-az" : "single-az"
  maintenance_window   = "sun:05:00-sun:06:00"

  tags = merge(var.tags, {
    Name       = "${var.customer_name}-${var.environment}-memcached",
    Deployment = "standard"
  })
}

##########################################################
#             Elastic Cache Serverless                   #
##########################################################
resource "aws_elasticache_serverless_cache" "serverless" {
  count = var.serverless_configuration.enabled ? 1 : 0

  name                 = "${var.customer_name}-${var.environment}-${var.elastic_cache_type}-serverless"
  description          = "Serverless ${var.elastic_cache_type} for ${var.customer_name} in ${var.environment}"
  engine               = var.elastic_cache_type
  major_engine_version = split(".", var.engine_version)[0]
  security_group_ids   = var.security_group_ids
  subnet_ids           = var.data_subnet_ids

  dynamic "cache_usage_limits" {
    for_each = [var.serverless_configuration.usage_limits]
    content {
      dynamic "data_storage" {
        for_each = [cache_usage_limits.value.data_storage]
        content {
          maximum = data_storage.value.maximum
          unit    = data_storage.value.unit
        }
      }
      dynamic "ecpu_per_second" {
        for_each = [cache_usage_limits.value.ecpu]
        content {
          maximum = ecpu_per_second.value.maximum
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name       = "${var.customer_name}-${var.environment}-${var.elastic_cache_type}-serverless",
    Deployment = "serverless"
  })
}