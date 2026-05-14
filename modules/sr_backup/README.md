<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_backup_plan.plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_selection.backup_selection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_vault.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_iam_role.role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backup_schedule_daily"></a> [backup\_schedule\_daily](#input\_backup\_schedule\_daily) | Agendamento diário de backup (default: todo dia às 3:00 UTC) | `string` | `"cron(0 3 * * ? *)"` | no |
| <a name="input_backup_schedule_monthly"></a> [backup\_schedule\_monthly](#input\_backup\_schedule\_monthly) | Agendamento mensal de backup (default: todo dia 1 às 3:00 UTC) | `string` | `"cron(0 3 1 * ? *)"` | no |
| <a name="input_backup_schedule_weekly"></a> [backup\_schedule\_weekly](#input\_backup\_schedule\_weekly) | Agendamento semanal de backup (default: todo domingo às 3:00 UTC) | `string` | `"cron(0 3 ? * 7 *)"` | no |
| <a name="input_customer-name"></a> [customer-name](#input\_customer-name) | Nome do cliente que utilizará o Backup | `string` | n/a | yes |
| <a name="input_delete_after_days_daily"></a> [delete\_after\_days\_daily](#input\_delete\_after\_days\_daily) | Tempo de delete do plano diario | `string` | `"7"` | no |
| <a name="input_delete_after_days_monthly"></a> [delete\_after\_days\_monthly](#input\_delete\_after\_days\_monthly) | Tempo de delete do plano mensal | `string` | `"365"` | no |
| <a name="input_delete_after_days_weekly"></a> [delete\_after\_days\_weekly](#input\_delete\_after\_days\_weekly) | Tempo de delete do plano semanal | `string` | `"30"` | no |
| <a name="input_enable_daily_backup"></a> [enable\_daily\_backup](#input\_enable\_daily\_backup) | Ativar backup diário | `bool` | n/a | yes |
| <a name="input_enable_monthly_backup"></a> [enable\_monthly\_backup](#input\_enable\_monthly\_backup) | Ativar backup mensal | `bool` | n/a | yes |
| <a name="input_enable_weekly_backup"></a> [enable\_weekly\_backup](#input\_enable\_weekly\_backup) | Ativar backup semanal | `bool` | n/a | yes |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Nome do ambiente em que o Backup será provisionado. Valores permitidos: [prd \| stg \| qa \| dev \| labs] | `string` | n/a | yes |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Nome da role IAM para backup | `string` | `"aws_backup_role"` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | KMS Key ARN para criptografia (opcional) | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | Região do cliente | `string` | n/a | yes |
| <a name="input_resources"></a> [resources](#input\_resources) | List of ARNs of the resources to be backed up | `list(string)` | `[]` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->