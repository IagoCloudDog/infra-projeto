# Terraform WordPress Infrastructure

Este repositório contém a infraestrutura como código (IaC) para provisionamento de um site WordPress completo na AWS usando Terraform. A infraestrutura inclui todos os componentes necessários para um WordPress escalável, seguro e monitorado.

## Estrutura do Projeto

```
clouddog-terraform-solution-wordpress/
├── modules/                   # Módulos Terraform reutilizáveis
│   ├── clouddog-acm/          # Certificados SSL/TLS
│   ├── clouddog-alb/          # Application Load Balancer
│   ├── clouddog-autoscaling/  # Auto Scaling Group
│   ├── clouddog-backup/       # AWS Backup
│   ├── clouddog-budget/       # Controle de orçamento
│   ├── clouddog-cloudfront/   # CDN CloudFront
│   ├── clouddog-cloudwatch/   # Monitoramento
│   ├── clouddog-ec2/          # Instâncias EC2
│   ├── clouddog-efs/          # Elastic File System
│   ├── clouddog-nlb/          # Network Load Balancer
│   ├── clouddog-openvpn/      # Servidor OpenVPN
│   ├── clouddog-rds/          # Banco de dados RDS
│   ├── clouddog-redis/        # Cache Redis
│   ├── clouddog-sg/           # Security Groups
│   └── clouddog-vpc/          # Virtual Private Cloud
├── data.tf                    # Fontes de dados
├── locals.tf                  # Variáveis locais
├── main.tf                    # Configuração principal
├── provider.tf                # Configuração do provider AWS
├── terraform.tfvars           # Valores das variáveis
├── variables.tf               # Definição de variáveis
└── versions.tf                # Versões dos providers
```

## Arquitetura da Solução

### Componentes Principais

**1. Rede (VPC)**
- VPC com subnets públicas, privadas (app) e de dados
- NAT Gateway para acesso à internet das subnets privadas
- Internet Gateway para subnets públicas
- Suporte a múltiplas Availability Zones

**2. Computação**
- Instâncias EC2 com suporte a arquiteturas x86 e Graviton
- Auto Scaling Group para escalabilidade automática
- Launch Template para padronização das instâncias
- Elastic File System (EFS) para armazenamento compartilhado

**3. Banco de Dados**
- RDS (MySQL/MariaDB/PostgreSQL/Oracle)
- ElastiCache Redis para cache
- Backups automáticos configurados

**4. Load Balancer e CDN**
- Application Load Balancer (ALB)
- Network Load Balancer (NLB) para SFTP
- CloudFront para distribuição de conteúdo
- Certificados SSL/TLS via ACM

**5. Segurança**
- Security Groups configurados por camada
- OpenVPN para acesso seguro
- Certificados SSL automáticos

**6. Monitoramento e Backup**
- CloudWatch para métricas e logs
- AWS Backup para proteção de dados
- Alertas de orçamento configurados

## Variáveis de Configuração

### Exemplo - Variáveis do Cliente
```hcl
# Nome, ambiente, região e tipo de projeto do cliente
customer_name    = "anycompany"
environment_name = "prd"
region           = "us-east-1"
project_name     = "Modernization"
account_id       = "102306345761"
```

### Exemplo - Variáveis de Orçamento
```hcl
# Chave e valor da tag para o budget filtrar
budget_filter_tag   = "Project"
budget_filter_value = "Modernization"

# Valores diários e mensais do budget
daily_budget_value   = "2.85"
monthly_budget_value = "70"

budget_subscriptions = {
  "sns_subscription" = {
    # Protocolo do SNS. Pode ser "https" ou "email"
    protocol = "email"
    # Endpoint do OpsGenie ou o email
    endpoint = "user@domain.com"
  }
}
```

### Exemplo - Variáveis de Rede (VPC)
```hcl
# Range de IP da VPC
vpc_cidr = "10.1.0.0/16"

# Número de AZs
number_of_azs = 2

# Decide se terá IPV6 ou não
enable_ipv6 = false

# Decidem quais subnets que serão criadas
create_public_subnets = true
create_app_subnets    = true
create_data_subnets   = true

# Decide se criará NAT Gateway ou não
create_nat = true

# Decide se o NAT Gateway será de alta disponibilidade ou não
nat_gateway_high_availability = false
```

### Exemplo - Variáveis de Computação (EC2)
```hcl
# Versão do PHP que será instalada na instância
php_version = 8.1

# Tipo de instância do servidor de aplicação
ec2_instance_type = "t4g.small"

# Arquitetura da instância. Pode ser "x86" ou "graviton"
os_arch = "graviton"

# Tamanho do armazenamento EBS
volume_size = 8

# Decide se o SFTP será criado ou não
enable_sftp = true
```

### Exemplo - Variáveis de RDS
```hcl
# Engine do RDS. Pode ser "mysql", "mariadb", "postgres" ou "oracle"
rds_engine = "mysql"

# Versão do Banco de Dados do RDS
rds_engine_version         = "8.0"
rds_parameter_group_family = "mysql8.0"
rds_major_engine_version   = "8.0"

# Tipo de instância do RDS
rds_instance_class = "db.t4g.small"

# Tamanho do armazenamento do Banco de Dados
rds_allocated_storage = 20

# Nome do Banco de Dados
rds_db_name = "clouddog"

# Nome do usuário Master do Banco de Dados
rds_username = "clouddog"

# Porta em que o Banco de Dados será exposto
rds_port = "3306"
```

### Exemplo - Variáveis de ElastiCache
```hcl
# Decide a configuração do Elasticache Redis
compute_configuration = {
  enabled                 = true
  node_type               = "cache.t4g.small"
  num_node_groups         = 1
  replicas_per_node_group = 1
  automatic_failover      = false
  multi_az                = false
}
```

### Exemplo - Variáveis de ACM
```hcl
# Domínio utilizado para criar o ACM
domain_name               = "anycompany.devops.clouddog.com.br"
subject_alternative_names = ["*.anycompany.devops.clouddog.com.br"]

# Método de validação do ACM. Pode ser "DNS" ou "EMAIL"
validation_method = "DNS"

# Decide se criará uma hosted zone para o certificado
create_hosted_zone = false

# ID da Hosted Zone. Necessário caso 'create_hosted_zone' for 'false'
hosted_zone_id = "Z073286124C5AYAHJPICT"
```

### Exemplo - Variáveis de Backup
```hcl
# Decide o tipo de backup que será feito nas instâncias
daily_backup   = "False"
weekly_backup  = "False"
monthly_backup = "False"
```

### Exemplo - Variáveis de OpenVPN
```hcl
# Tipo de instância da OpenVPN
openvpn_instance_type = "t4g.small"
```

### Exemplo - Variáveis de EFS
```hcl
performance_mode = "generalPurpose"
throughput_mode  = "provisioned"

# TroughPut desejado para o EFS
provisioned_throughput_in_mibps = 2
```

### Exemplo - Variáveis de Security Groups
```hcl
# Configuração de criação dos security groups
sg_config = {
  create_efs_security_group = true
  create_app_security_group = true
  create_db_security_group  = true
  create_alb_security_group = true
  create_vpn_security_group = true
  create_nlb_security_group = true
}

# Porta do banco de dados relacional
database_port = 3306

# Porta do banco de dados redis
redis_port = 6379
```

### Exemplo - Variáveis de Auto Scaling
```hcl
# Decide se o Auto Scaling Group será criado ou não. Deve ser ativado somente após o provisionamento da EC2 ser concluído.
enable_asg = true

# Decidem qual o tipo de scaling que será utilizado pelo Auto Scaling Group.
enable_cpu_scaling     = false
enable_network_scaling = true

# Quantidade de máquinas desejadas do AutoScaling
asg_desired_capacity = 2

# Quantidade mínima de máquinas do AutoScaling
asg_min_size = 2

# Quantidade máxima de máquinas do AutoScaling
asg_max_size = 2

# Tipo de instância que o AutoScaling provisionará
lt_instance_type = "t4g.medium"
```

### Exemplo - Variáveis de ALB
```hcl
# Decide se o ALB terá proteção contra deletion ou não
enable_deletion_protection = false

# Decide se o ALB terá logs ou não
enable_alb_logs = false
```

### Exemplo - Variáveis de CloudWatch
```hcl
# Decide se o dashboard do CloudWatch será criado ou não. Deve ser ativado somente após o provisionamento de todos os recursos.
create_dashboard = false

# Variável de inscrição de alerta do CloudWatch. O CloudWatch deve ser provisionado somente após o provisionaento da infra completa.
cloudwatch_subscriptions = {
  "sns_subscription" = {
    # Protocolo do SNS. Pode ser "https" ou "email"
    protocol = "email"
    # Endpoint do OpsGenie ou o email
    endpoint = "user@domain.com"
  }
}
```

## Novas Features

### Network Load Balancer (NLB)
- **SFTP Support**: NLB configurado para suporte a SFTP na porta 22
- **Alta Performance**: Load balancer de camada 4 para tráfego TCP
- **Integração com Auto Scaling**: Target groups integrados ao ASG

### Security Groups Avançados
- **Configuração Flexível**: Controle granular sobre quais SGs criar
- **Suporte a NLB**: Security group específico para Network Load Balancer
- **Portas Configuráveis**: Database e Redis com portas configuráveis

### EFS Melhorado
- **Performance Modes**: Suporte a generalPurpose e maxIO
- **Throughput Modes**: Bursting, elastic e provisioned
- **Throughput Provisionado**: Configuração de throughput customizado

### Auto Scaling Avançado
- **Múltiplos Target Groups**: Suporte a ALB e NLB simultaneamente
- **Scaling Policies**: CPU e Network scaling configuráveis
- **Launch Template**: Configuração flexível de instâncias

## Como Provisionar

### Pré-requisitos

1. **Terraform instalado** (versão >= 1.0)
2. **AWS CLI configurado** com credenciais adequadas
3. **Permissões AWS** necessárias para criar os recursos
4. **Domínio registrado** (se usar certificados SSL)

### Passos para Provisionamento

1. **Clone o repositório**
```bash
git clone https://github.com/clouddog-br/clouddog-terraform-solution-wordpress.git
```

2. **Inicialize o Terraform**
```bash
terraform init
```

3. **Valide a configuração**
```bash
terraform validate
```

4. **Planeje a infraestrutura**
```bash
terraform plan -var-file=terraform.tfvars
```

5. **Aplique a configuração**
```bash
terraform apply -var-file=terraform.tfvars
```

### Ordem de Provisionamento Recomendada

1. **Primeira execução** - Desabilite o CloudWatch:
```hcl
create_dashboard = false
```

2. **Após todos os recursos serem provisionados** - Habilite o CloudWatch:
```hcl
create_dashboard = true
```

3. **Execute novamente**:
```bash
terraform apply -var-file=terraform.tfvars
```

## Security Groups

O módulo configura automaticamente os seguintes Security Groups:

- **ALB Security Group**: Permite tráfego HTTP/HTTPS da internet
- **NLB Security Group**: Permite tráfego SFTP (porta 22)
- **App Security Group**: Permite tráfego do ALB/NLB e SSH da VPN
- **Database Security Group**: Permite tráfego das instâncias de aplicação
- **EFS Security Group**: Permite NFS das instâncias de aplicação
- **VPN Security Group**: Permite OpenVPN da internet

## Monitoramento e Alertas

### CloudWatch
- Métricas de CPU, memória e rede
- Logs de aplicação centralizados
- Dashboards automáticos

### Alertas de Orçamento
- Notificações por email quando limites são atingidos
- Monitoramento diário e mensal
- Filtros por tags de projeto

### Backup
- Backup automático de instâncias EC2
- Backup do RDS configurado
- Retenção configurável

## Acesso e Segurança

### OpenVPN
- Servidor OpenVPN provisionado automaticamente
- Acesso seguro aos recursos internos
- Configuração automática

### Certificados SSL
- Certificados automáticos via ACM
- Validação por DNS
- Renovação automática

## Comandos Úteis

### Verificar estado atual
```bash
terraform show
```

### Listar recursos
```bash
terraform state list
```

### Destruir infraestrutura (cuidado!)
```bash
terraform destroy -var-file=terraform.tfvars
```


## Troubleshooting

### Problemas Comuns

1. **Erro de certificado SSL**
   - Verifique se o domínio está configurado corretamente
   - Confirme se a zona do Route53 existe

2. **Auto Scaling não funciona**
   - Certifique-se de que a EC2 principal foi provisionada primeiro
   - Verifique se `enable_asg = true`

3. **Erro de permissões**
   - Verifique as credenciais AWS
   - Confirme as permissões IAM necessárias

### Logs e Debugging

```bash
# Habilitar logs detalhados
export TF_LOG=DEBUG
terraform apply -var-file=terraform.tfvars
```

## Custos Estimados

Os custos variam conforme a configuração, mas uma estimativa base inclui:

- **EC2 t4g.medium**: ~$25/mês
- **RDS db.t4g.small**: ~$15/mês  
- **ALB**: ~$20/mês
- **NLB**: ~$20/mês
- **NAT Gateway**: ~$45/mês
- **EFS**: ~$0.30/GB/mês
- **CloudFront**: Baseado no uso
- **OpenVPN t4g.micro**: ~$8/mês

**Total estimado**: ~$133-180/mês (configuração básica)

Use o [AWS Pricing Calculator](https://calculator.aws) para estimativas precisas.
