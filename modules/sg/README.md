# CloudDog Security Groups Module

Este módulo provisiona Security Groups configuráveis para todos os componentes da infraestrutura WordPress.

## Recursos Criados

- **ALB Security Group**: Para Application Load Balancer
- **NLB Security Group**: Para Network Load Balancer  
- **App Security Group**: Para instâncias de aplicação
- **Database Security Group**: Para RDS e Redis
- **EFS Security Group**: Para Elastic File System
- **VPN Security Group**: Para servidor OpenVPN
- **Managed Prefix List**: Para IPs administrativos

## Uso

```hcl
module "clouddog-sg" {
  source = "./modules/clouddog-sg"

  customer_name    = "cliente"
  environment_name = "prod"
  vpc_id           = "vpc-12345678"
  
  database_port = 3306
  redis_port    = 6379
  
  config = {
    create_efs_security_group = true
    create_app_security_group = true
    create_db_security_group  = true
    create_alb_security_group = true
    create_vpn_security_group = true
    create_nlb_security_group = true
  }
  
  admin_ips = [
    {
      ip          = "203.0.113.0/32"
      description = "Office IP"
    }
  ]
  
  tags = {}
}
```

## Variáveis Principais

| Nome | Descrição | Tipo | Obrigatório |
|------|-----------|------|-------------|
| customer_name | Nome do cliente | string | Sim |
| environment_name | Ambiente (prd/stg/qa/dev/labs) | string | Sim |
| vpc_id | ID da VPC | string | Sim |
| database_port | Porta do banco de dados | number | Sim |
| redis_port | Porta do Redis | number | Sim |
| config | Configuração de quais SGs criar | object | Sim |
| admin_ips | Lista de IPs administrativos | list(object) | Sim |
| tags | Tags adicionais | map(string) | Sim |

## Configuração dos Security Groups

```hcl
config = {
  create_efs_security_group = true   # SG para EFS
  create_app_security_group = true   # SG para aplicação
  create_db_security_group  = true   # SG para banco de dados
  create_alb_security_group = true   # SG para ALB
  create_vpn_security_group = true   # SG para VPN
  create_nlb_security_group = true   # SG para NLB
}
```

## Regras de Segurança

### ALB Security Group
- **Ingress**: HTTP (80) e HTTPS (443) de qualquer lugar
- **Egress**: Tráfego para App Security Group

### NLB Security Group  
- **Ingress**: TCP (22) de qualquer lugar para SFTP
- **Egress**: Tráfego para App Security Group

### App Security Group
- **Ingress**: Tráfego do ALB/NLB, SSH dos IPs administrativos
- **Egress**: Todo tráfego de saída

### Database Security Group
- **Ingress**: Porta do banco (MySQL/PostgreSQL) do App SG
- **Ingress**: Porta do Redis (6379) do App SG
- **Egress**: Limitado

### EFS Security Group
- **Ingress**: NFS (2049) do App Security Group
- **Egress**: Limitado

### VPN Security Group
- **Ingress**: OpenVPN (1194 UDP) de qualquer lugar
- **Ingress**: SSH (22) dos IPs administrativos
- **Egress**: Todo tráfego de saída

## Outputs

| Nome | Descrição |
|------|-----------|
| alb_security_group_id | ID do Security Group do ALB |
| nlb_security_group_id | ID do Security Group do NLB |
| application_security_group_id | ID do Security Group da aplicação |
| db_security_group_id | ID do Security Group do banco de dados |
| efs_security_group_id | ID do Security Group do EFS |
| vpn_security_group_id | ID do Security Group da VPN |

## Features

- **Configuração Flexível**: Controle granular sobre quais SGs criar
- **Regras Customizáveis**: Suporte a regras personalizadas de ingress/egress
- **Managed Prefix Lists**: Gerenciamento centralizado de IPs administrativos
- **Portas Configuráveis**: Database e Redis com portas configuráveis
- **Integração Completa**: SGs integrados entre todos os componentes