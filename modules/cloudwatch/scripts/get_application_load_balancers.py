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
    print("Erro: Nenhum arquivo .tfvars foi encontrado no diretório atual.", file=sys.stderr)
    sys.exit(1) # Termina o script com um código de erro

# Usa o primeiro arquivo .tfvars encontrado
tfvars_file_path = tfvars_files[0]
print(f"Info: Usando o arquivo de variáveis '{tfvars_file_path}'", file=sys.stderr)

# 4. Lê a região do arquivo encontrado
try:
    with open(tfvars_file_path, "r") as tfvars_file:
        tfvars = hcl2.load(tfvars_file)
except Exception as e:
    print(f"Erro ao ler ou analisar o arquivo {tfvars_file_path}: {e}", file=sys.stderr)
    sys.exit(1)

region = tfvars.get("region")

# 5. Verifica se a variável 'region' foi encontrada no arquivo
if not region:
    print(f"Erro: A variável 'region' não foi encontrada dentro de {tfvars_file_path}.", file=sys.stderr)
    sys.exit(1)

# --- FIM DA MODIFICAÇÃO ---

# O restante do código permanece o mesmo, apenas com tratamento de erros
# Inicializa o cliente AWS para ELBv2
try:
    client = boto3.client('elbv2', region_name=region)

    # Obtém a lista de load balancers
    response = client.describe_load_balancers()

    # Filtra apenas os Application Load Balancers (ALBs)
    load_balancers = [
        lb['LoadBalancerName']
        for lb in response['LoadBalancers']
        if lb['Type'] == 'application'  # Filtro para ALBs mantido
    ]

    # Transforma a lista em um mapa de strings
    map_output = {lb: lb for lb in load_balancers}

    # Converte o mapa para uma string JSON formatada
    map_output_json = json.dumps(map_output, indent=2) # Adicionado indent para melhor leitura

    print(map_output_json)

except Exception as e:
    print(f"Erro ao interagir com a AWS: {e}", file=sys.stderr)
    sys.exit(1)