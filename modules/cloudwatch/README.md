# CloudDog CloudWatch Module

Este módulo provisiona dashboard de monitoramento e alarmes CloudWatch para todos os recursos AWS da infraestrutura.

## Recursos Criados

- **CloudWatch Dashboard**: Dashboard unificado com métricas de todos os recursos
- **SNS Topic**: Tópico para notificações de alarmes
- **CloudWatch Alarms**: Alarmes para EC2, RDS, EFS, Redis, ALB e ASG
- **SNS Subscriptions**: Assinaturas para notificações por email/HTTPS

## Uso

```hcl
module "clouddog-cloudwatch" {
  source = "./modules/clouddog-cloudwatch"

  customer_name            = "cliente"
  environment_name         = "prod"
  aws_region              = "us-east-1"
  
  cloudwatch_subscriptions = {
    "email_alert" = {
      protocol = "email"
      endpoint = "admin@empresa.com"
    }
  }
}
```

## Variáveis

| Nome | Descrição | Tipo | Obrigatório |
|------|-----------|------|-------------|
| customer_name | Nome do cliente | string | Sim |
| environment_name | Ambiente (prd/stg/qa/dev/labs) | string | Sim |
| aws_region | Região AWS | string | Sim |
| cloudwatch_subscriptions | Configurações de notificação | map(object) | Sim |

## Alarmes Configurados

### EC2
- **CPU Utilization** > 80%
- **Memory Utilization** > 80%
- **Disk Utilization** > 80%
- **Status Check Failed**
- **EBS Status Check Failed**
- **CPU Credit Balance** < 40% (instâncias T)

### RDS
- **CPU Utilization** > 80%
- **Free Memory** < 20%
- **Free Storage** < 20%
- **Database Connections** > limite máximo

### ALB
- **5XX Error Rate** > 5%

### EFS
- **Throughput Utilization** > 80%
- **IO Limit** > 80%
- **Client Connections** = 0

### Redis
- **CPU Utilization** > 80%

### Auto Scaling Group
- **Active Instances** = 0

## Dashboard Widgets

O dashboard inclui métricas organizadas por serviço:
- Application Load Balancer
- Network Load Balancer  
- EC2 Instances
- RDS Databases
- Redis Clusters
- EFS File Systems
- Auto Scaling Groups