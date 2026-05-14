# CloudDog ALB Module

Este módulo provisiona Application Load Balancer (ALB) com listeners HTTP/HTTPS, target groups e configurações de logs.

## Recursos Criados

- **Application Load Balancer**: Load balancer de camada 7
- **HTTP Listener**: Listener na porta 80 (redirect para HTTPS)
- **HTTPS Listener**: Listener na porta 443 com certificado SSL
- **Target Groups**: Target groups para aplicação e OpenVPN
- **S3 Bucket**: Bucket para logs do ALB (opcional)

## Uso

```hcl
module "clouddog-alb" {
  source = "./modules/clouddog-alb"

  customer_name = "cliente"
  environment   = "prod"
  
  alb_security_group_id = ["sg-12345678"]
  alb_subnet_ids        = ["subnet-12345", "subnet-67890"]
  certificate_arns      = ["arn:aws:acm:us-east-1:123456789012:certificate/..."]
  
  vpc_id              = "vpc-12345678"
  instance_id         = "i-1234567890abcdef0"
  openvpn_instance_id = "i-0987654321fedcba0"
  
  host_header         = "app.exemplo.com"
  openvpn_host_header = "openvpn.exemplo.com"
  
  enable_deletion_protection = false
  enable_alb_logs           = false
  
  tags = {}
}
```

## Variáveis

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|-------------|
| customer_name | Nome do cliente | string | - | Sim |
| environment | Ambiente (dev/stg/prd) | string | - | Sim |
| alb_security_group_id | IDs dos security groups | list(string) | - | Sim |
| alb_subnet_ids | IDs das subnets públicas | list(string) | - | Sim |
| certificate_arns | ARNs dos certificados ACM | list(string) | [] | Não |
| vpc_id | ID da VPC | string | - | Sim |
| instance_id | ID da instância principal | string | - | Sim |
| openvpn_instance_id | ID da instância OpenVPN | string | - | Sim |
| host_header | Host header da aplicação | string | - | Sim |
| openvpn_host_header | Host header do OpenVPN | string | - | Sim |
| enable_deletion_protection | Proteção contra deleção | bool | - | Sim |
| enable_alb_logs | Habilitar logs do ALB | bool | false | Não |
| tags | Tags adicionais | map(string) | - | Sim |

## Outputs

| Nome | Descrição |
|------|-----------|
| alb_arn | ARN do Application Load Balancer |
| alb_dns_name | DNS name do ALB |
| alb_zone_id | Zone ID do ALB |
| alb_id | ID do ALB |
| target_group_arn | ARN do target group principal |
| alb_arn_suffix | ARN suffix do ALB |
| target_group_arn_suffix | ARN suffix do target group |

## Configurações

- **Tipo**: Application Load Balancer (camada 7)
- **Listeners**: HTTP (80) → HTTPS redirect, HTTPS (443)
- **Target Groups**: Aplicação principal e OpenVPN
- **Health Check**: HTTP na porta 80
- **SSL Policy**: ELBSecurityPolicy-TLS-1-2-2017-01
- **Logs**: S3 bucket opcional para access logs
