output "subnet_group_name" {
  value       = aws_elasticache_subnet_group.subnet_group.name
  description = "Name of the ElastiCache subnet group"
}

output "parameter_group_name" {
  value       = try(aws_elasticache_parameter_group.parameter_group[0].name, null)
  description = "Name of the ElastiCache parameter group"
}

output "redis_primary_endpoint" {
  value       = try(aws_elasticache_replication_group.standard[0].primary_endpoint_address, null)
  description = "Primary endpoint for Redis/Valkey"
}

output "redis_reader_endpoint" {
  value       = try(aws_elasticache_replication_group.standard[0].reader_endpoint_address, null)
  description = "Reader endpoint for Redis/Valkey"
}

output "memcached_endpoint" {
  value       = try(join(",", aws_elasticache_cluster.memcached[0].configuration_endpoint), null)
  description = "Configuration endpoint for Memcached"
}

output "serverless_endpoint" {
  value       = try(aws_elasticache_serverless_cache.serverless[0].endpoint, null)
  description = "Endpoint for ElastiCache Serverless"
}

output "cluster_id" {
  value       = try(aws_elasticache_cluster.memcached[0].cluster_id, null)
  description = "ID of the Elasticache Cluster"
}
