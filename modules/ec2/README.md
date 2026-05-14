<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.ec2-instance-profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.ec2-policy-terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ec2-role-terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ec2_cloudwatch_agent_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ec2_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.ec2_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_key_pair.ec2-key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_s3_bucket.ec2-bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_object.pastaChaveBucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.private-key-pair-file](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [tls_private_key.ec2-key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_ami.debian_amd64](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.debian_arm64](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.ubuntu_arm64](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.ubuntu_jammy_amd64](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.winserver2019](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.winserver2022](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [template_file.cloudwatch_agent](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Nome da aplicação que será utilizada na EC2 | `string` | n/a | yes |
| <a name="input_create_policy"></a> [create\_policy](#input\_create\_policy) | Decide se a policy será ou não criada | `bool` | `true` | no |
| <a name="input_create_role"></a> [create\_role](#input\_create\_role) | Decide se a role será ou não criada | `bool` | `true` | no |
| <a name="input_customer_name"></a> [customer\_name](#input\_customer\_name) | Nome do Cliente | `string` | n/a | yes |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Nome do ambiente em que a EC2 será provisionada. Valores permitidos: [prd \| stg \| qa \| dev \| labs] | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | O tipo de instância que será provisionada. Ex: 't2.micro' | `string` | n/a | yes |
| <a name="input_os_arch"></a> [os\_arch](#input\_os\_arch) | Arquitetura do Sistema Operacional que será instalado na EC2. Valores permitidos: [debian\_arm64 \| debian\_amd64 \| ubuntu\_arm64 \|ubuntu\_amd64 \| winserver2022 \| winserver2019] | `string` | n/a | yes |
| <a name="input_public_ip"></a> [public\_ip](#input\_public\_ip) | Decide se criará ou não um IP Público | `bool` | `false` | no |
| <a name="input_region"></a> [region](#input\_region) | Região em que a EC2 será provisionada | `string` | n/a | yes |
| <a name="input_security_group_id"></a> [security\_group\_id](#input\_security\_group\_id) | O ID do Security Group que estará associado à EC2 | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | O ID da Subnet que a EC2 será provisionaada | `string` | n/a | yes |
| <a name="input_volume_size"></a> [volume\_size](#input\_volume\_size) | O tamanho do volume que será provisionado (opcional). | `number` | `30` | no |
| <a name="input_volume_type"></a> [volume\_type](#input\_volume\_type) | O tipo de volume que será provisionado (opcional). Valores permitidos: [gp3 \| gp2 \| io1 \| io2 \| sc1 \| st1] | `string` | `"gp3"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ec2_arn"></a> [ec2\_arn](#output\_ec2\_arn) | ARN da EC2 provisionada |
| <a name="output_ec2_id"></a> [ec2\_id](#output\_ec2\_id) | ID da EC2 provisionada |
| <a name="output_ec2_name"></a> [ec2\_name](#output\_ec2\_name) | Nome da EC2 provisionada |
| <a name="output_s3_id"></a> [s3\_id](#output\_s3\_id) | ID do bucket S3 que armazena a chave PEM |
| <a name="output_s3_name"></a> [s3\_name](#output\_s3\_name) | Nome do bucket S3 que armazena a chave PEM |
<!-- END_TF_DOCS -->