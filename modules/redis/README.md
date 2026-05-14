## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_elasticache_cluster.memcached](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_cluster) | resource |
| [aws_elasticache_parameter_group.parameter_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_parameter_group) | resource |
| [aws_elasticache_replication_group.standard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group) | resource |
| [aws_elasticache_serverless_cache.serverless](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_serverless_cache) | resource |
| [aws_elasticache_subnet_group.subnet_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_compute_configuration"></a> [compute\_configuration](#input\_compute\_configuration) | Configuration for standard Redis deployment | <pre>object({<br/>    enabled               = bool<br/>    node_type            = string<br/>    num_node_groups       = number<br/>    replicas_per_node_group = number<br/>    automatic_failover    = bool<br/>    multi_az             = bool<br/>  })</pre> | <pre>{<br/>  "automatic_failover": false,<br/>  "enabled": false,<br/>  "multi_az": false,<br/>  "node_type": "cache.t3.micro",<br/>  "num_node_groups": 1,<br/>  "replicas_per_node_group": 1<br/>}</pre> | no |
| <a name="input_customer_name"></a> [customer\_name](#input\_customer\_name) | Name of the customer this Redis cluster belongs to | `string` | n/a | yes |
| <a name="input_data_subnet_ids"></a> [data\_subnet\_ids](#input\_data\_subnet\_ids) | List of subnet data IDs where Redis will be deployed | `list(string)` | n/a | yes |
| <a name="input_elastic_cache_type"></a> [elastic\_cache\_type](#input\_elastic\_cache\_type) | value | `string` | n/a | yes |
| <a name="input_encryption"></a> [encryption](#input\_encryption) | Encryption configuration | <pre>object({<br/>    at_rest    = bool<br/>    transit    = bool<br/>  })</pre> | <pre>{<br/>  "at_rest": true,<br/>  "transit": false<br/>}</pre> | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Cache engine version | `string` | `"7.0"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment (e.g., dev, staging, prod) | `string` | n/a | yes |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | List of security group IDs to attach to Redis | `list(string)` | n/a | yes |
| <a name="input_serverless_configuration"></a> [serverless\_configuration](#input\_serverless\_configuration) | Configuration for serverless Memcached deployment | <pre>object({<br/>    enabled       = bool<br/>    usage_limits = object({<br/>      data_storage = object({<br/>        maximum = number<br/>        unit    = string<br/>      })<br/>      ecpu = object({<br/>        maximum = number<br/>      })<br/>    })<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "usage_limits": {<br/>    "data_storage": {<br/>      "maximum": 50,<br/>      "unit": "GB"<br/>    },<br/>    "ecpu": {<br/>      "maximum": 1000<br/>    }<br/>  }<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags for resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_memcached_endpoint"></a> [memcached\_endpoint](#output\_memcached\_endpoint) | Configuration endpoint for Memcached |
| <a name="output_parameter_group_name"></a> [parameter\_group\_name](#output\_parameter\_group\_name) | Name of the ElastiCache parameter group |
| <a name="output_redis_primary_endpoint"></a> [redis\_primary\_endpoint](#output\_redis\_primary\_endpoint) | Primary endpoint for Redis/Valkey |
| <a name="output_redis_reader_endpoint"></a> [redis\_reader\_endpoint](#output\_redis\_reader\_endpoint) | Reader endpoint for Redis/Valkey |
| <a name="output_serverless_endpoint"></a> [serverless\_endpoint](#output\_serverless\_endpoint) | Endpoint for ElastiCache Serverless |
| <a name="output_subnet_group_name"></a> [subnet\_group\_name](#output\_subnet\_group\_name) | Name of the ElastiCache subnet group |
