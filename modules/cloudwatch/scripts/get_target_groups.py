import boto3
import json
import hcl2
import glob  # 1. Importa a biblioteca glob
import sys   # Importa a biblioteca sys para sair do script em caso de erro

# --- INÍCIO DA MODIFICAÇÃO ---

# 2. Procura por qualquer arquivo que termine com .tfvars
tfvars_files = glob.glob('./*.tfvars')

# 3. Verifica se algum arquivo foi encontrado
if not tfvars_files:
    # Imprime o erro como JSON para manter a consistência da saída
    print(json.dumps({"error": "Nenhum arquivo .tfvars foi encontrado no diretório atual."}))
    sys.exit(1)

# Usa o primeiro arquivo .tfvars encontrado
tfvars_file_path = tfvars_files[0]
# Imprime informações de diagnóstico no erro padrão para não poluir a saída JSON
print(f"Info: Usando o arquivo de variáveis '{tfvars_file_path}'", file=sys.stderr)

# 4. Lê a região do arquivo encontrado
try:
    with open(tfvars_file_path, "r") as tfvars_file:
        tfvars = hcl2.load(tfvars_file)
except Exception as e:
    print(json.dumps({"error": f"Erro ao ler ou analisar o arquivo {tfvars_file_path}: {e}"}))
    sys.exit(1)

region = tfvars.get("region")

# 5. Verifica se a variável 'region' foi encontrada no arquivo
if not region:
    print(json.dumps({"error": f"A variável 'region' não foi encontrada dentro de {tfvars_file_path}."}))
    sys.exit(1)

# --- FIM DA MODIFICAÇÃO ---

try:
    # Inicializa o cliente AWS para ELBv2
    client = boto3.client('elbv2', region_name=region)

    # Dicionário para armazenar os ALBs e seus target groups
    output = {}
    
    # Usa um paginador para garantir que todos os LBs sejam listados
    paginator = client.get_paginator('describe_load_balancers')
    for page in paginator.paginate():
        # Para cada ALB, obtém os target groups associados
        for lb in page['LoadBalancers']:
            load_balancer_name = lb['LoadBalancerName']
            load_balancer_arn = lb['LoadBalancerArn']
            
            # Obtém os target groups associados ao ALB
            tg_response = client.describe_target_groups(LoadBalancerArn=load_balancer_arn)
            
            # Junta os ARNs dos target groups como uma string delimitada por vírgulas
            output[load_balancer_name] = ",".join(
                tg["TargetGroupArn"] for tg in tg_response['TargetGroups']
            )

    # Retorna o dicionário como um JSON válido
    print(json.dumps(output, indent=2))

except Exception as e:
    print(json.dumps({"error": f"Erro ao interagir com a AWS: {str(e)}"}))
    sys.exit(1)