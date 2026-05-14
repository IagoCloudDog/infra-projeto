# CloudDog CloudFront Module

Este módulo provisiona uma distribuição CloudFront para CDN com certificado SSL e configurações otimizadas.

## Recursos Criados

- **CloudFront Distribution**: Distribuição CDN com origem no ALB
- **SSL Certificate**: Certificado ACM para HTTPS
- **Cache Policy**: Política de cache otimizada

## Uso

```hcl
module "clouddog-cloudfront" {
  source = "./modules/clouddog-cloudfront"

  customer_name    = "cliente"
  environment_name = "prod"
  
  domain_name     = "exemplo.com"
  alb_id          = "app-alb-123456789"
  certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."
  
  tags = {}
}
```

## Variáveis

| Nome | Descrição | Tipo | Obrigatório |
|------|-----------|------|-------------|
| customer_name | Nome do cliente | string | Sim |
| environment_name | Ambiente (prd/stg/qa/dev/labs) | string | Sim |
| domain_name | Domínio principal | string | Sim |
| alb_id | ID do ALB origem | string | Sim |
| certificate_arn | ARN do certificado ACM | string | Sim |
| tags | Tags adicionais | map(string) | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| cloudfront_domain | Domínio da distribuição CloudFront |

## Configurações

- **IPv6**: Habilitado
- **Protocolo**: HTTPS obrigatório (redirect HTTP → HTTPS)
- **SSL**: TLS 1.2+ com SNI
- **Cache**: Política otimizada para conteúdo web
- **Compressão**: Habilitada
- **Métodos**: GET, HEAD, OPTIONS