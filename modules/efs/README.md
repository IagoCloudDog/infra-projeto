# CloudDog EFS Module

Este módulo provisiona Elastic File System (EFS) com configurações de performance, throughput e políticas de segurança.

## Recursos Criados

- **EFS File System**: Sistema de arquivos com criptografia
- **Mount Targets**: Pontos de montagem nas subnets
- **Access Points**: Pontos de acesso configuráveis (opcional)
- **Backup Policy**: Política de backup automático
- **File System Policy**: Políticas de acesso e segurança

## Uso

```hcl
module "clouddog-efs" {
  source = "./modules/clouddog-efs"

  customer_name    = "cliente"
  environment_name = "prod"
  
  performance_mode                = "generalPurpose"
  throughput_mode                 = "bursting"
  provisioned_throughput_in_mibps = null
  encrypted                       = true
  
  security_group_efs = ["sg-12345678"]
  
  mount_targets = {
    "us-east-1a" = {
      subnet_id = "subnet-12345"
    }
    "us-east-1b" = {
      subnet_id = "subnet-67890"
    }
  }
  
  tags = {}
}
```

## Variáveis

| Nome | Descrição | Tipo | Padrão |
|------|-----------|------|--------|
| performance_mode | Modo de performance (generalPurpose/maxIO) | string | - |
| throughput_mode | Modo de throughput (bursting/elastic/provisioned) | string | - |
| provisioned_throughput_in_mibps | Throughput provisionado em MiB/s | number | null |
| encrypted | Habilitar criptografia | bool | - |
| security_group_efs | IDs dos security groups | list(string) | - |
| mount_targets | Configuração dos mount targets | map | {} |
| create_backup_policy | Criar política de backup | bool | true |
| enable_backup_policy | Habilitar backup automático | bool | true |

## Performance Modes

- **generalPurpose**: Menor latência por operação, até 7.000 operações/segundo
- **maxIO**: Maior latência, mas pode escalar para mais de 7.000 operações/segundo

## Throughput Modes

- **bursting**: Throughput escala com o tamanho do sistema de arquivos
- **elastic**: Throughput automático baseado na carga de trabalho
- **provisioned**: Throughput fixo independente do tamanho

## Outputs

| Nome | Descrição |
|------|-----------|
| efs_id | ID do sistema de arquivos EFS |

## Segurança

- Criptografia em repouso habilitada por padrão
- Políticas de acesso configuráveis
- Integração com Security Groups
- Suporte a transport encryption