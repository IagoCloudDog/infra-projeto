# CloudDog Auto Scaling Module

Este módulo provisiona Auto Scaling Group com Launch Template e políticas de escalabilidade baseadas em CPU ou ALB.

## Recursos Criados

- **AMI from Instance**: AMI criada a partir da instância EC2 principal
- **Launch Template**: Template para novas instâncias com configuração Spot
- **Auto Scaling Group**: Grupo de auto scaling com target groups
- **Scaling Policy**: Política de escalabilidade (CPU ou ALB)

## Uso

```hcl
module "clouddog-autoscaling" {
  source = "./modules/clouddog-autoscaling"

  customer_name    = "cliente"
  environment_name = "prod"
  
  enable_asg           = true
  ec2_instance_id      = "i-1234567890abcdef0"
  lt_instance_type     = "t4g.small"
  
  instances_desired_capacity = 2
  instances_min_size         = 1
  instances_max_size         = 5
  
  enable_cpu_scaling     = true
  enable_network_scaling = false
  
  vpc_zone_identifier = ["subnet-12345", "subnet-67890"]
  target_group_arns   = ["arn:aws:elasticloadbalancing:..."]
  
  tags = {}
}
```

## Variáveis

| Nome | Descrição | Tipo | Padrão |
|------|-----------|------|--------|
| enable_asg | Habilitar Auto Scaling | bool | - |
| ec2_instance_id | ID da instância base | string | - |
| lt_instance_type | Tipo da instância no template | string | - |
| instances_desired_capacity | Capacidade desejada | number | - |
| instances_min_size | Mínimo de instâncias | number | - |
| instances_max_size | Máximo de instâncias | number | - |
| enable_cpu_scaling | Scaling baseado em CPU | bool | true |
| enable_network_scaling | Scaling baseado em ALB | bool | false |
| cpu_target_value | Target de CPU (%) | number | 80 |
| alb_target_value | Target de requests por instância | number | 2000 |

## Features

- **Instâncias Spot**: Launch Template configurado para usar instâncias Spot
- **Múltiplos Target Groups**: Suporte a ALB e NLB simultaneamente
- **Scaling Flexível**: CPU ou ALB request-based scaling
- **Health Check**: ELB health check com grace period configurável