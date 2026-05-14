import boto3
import hcl2
import json
import glob  # 1. Importa a biblioteca glob
import sys   # Importa a biblioteca sys para sair do script em caso de erro

# --- INÍCIO DA MODIFICAÇÃO ---

# 2. Procura por qualquer arquivo que termine com .tfvars
tfvars_files = glob.glob('./*.tfvars')

# 3. Verifica se algum arquivo foi encontrado
if not tfvars_files:
    print(json.dumps({"error": "Nenhum arquivo .tfvars foi encontrado no diretório atual."}))
    sys.exit(1) # Termina o script com um código de erro

# Usa o primeiro arquivo .tfvars encontrado
tfvars_file_path = tfvars_files[0]
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


# Função para calcular Max Connections com base na memória da instância
def get_max_connections(db_instance):
    # Dicionário de memória por tipo de instância (em GB)
    instance_memory = {
        "db.t3.micro": 1, "db.t3.small": 2, "db.t3.medium": 4, "db.t3.large": 8, "db.t3.xlarge": 16, "db.t3.2xlarge": 32,
        "db.t4g.micro": 1, "db.t4g.small": 2, "db.t4g.medium": 4, "db.t4g.large": 8, "db.t4g.xlarge": 16, "db.t4g.2xlarge": 32,
        "db.m5.large": 8, "db.m5.xlarge": 16, "db.m5.2xlarge": 32, "db.m5.4xlarge": 64, "db.m5.8xlarge": 128, "db.m5.12xlarge": 192, "db.m5.16xlarge": 256, "db.m5.24xlarge": 384,
        "db.m6g.large": 8, "db.m6g.xlarge": 16, "db.m6g.2xlarge": 32, "db.m6g.4xlarge": 64, "db.m6g.8xlarge": 128, "db.m6g.12xlarge": 192, "db.m6g.16xlarge": 256,
        "db.r5.large": 16, "db.r5.xlarge": 32, "db.r5.2xlarge": 64, "db.r5.4xlarge": 128, "db.r5.8xlarge": 256, "db.r5.12xlarge": 384, "db.r5.16xlarge": 512, "db.r5.24xlarge": 768,
        "db.r6g.large": 16, "db.r6g.xlarge": 32, "db.r6g.2xlarge": 64, "db.r6g.4xlarge": 128, "db.r6g.8xlarge": 256, "db.r6g.12xlarge": 384, "db.r6g.16xlarge": 512,
        "db.x1.16xlarge": 976, "db.x1.32xlarge": 1952,
        "db.x2g.large": 16, "db.x2g.xlarge": 32, "db.x2g.2xlarge": 64, "db.x2g.4xlarge": 128, "db.x2g.8xlarge": 256, "db.x2g.12xlarge": 384, "db.x2g.16xlarge": 512,
        "db.z1d.large": 16, "db.z1d.xlarge": 32, "db.z1d.2xlarge": 64, "db.z1d.3xlarge": 96, "db.z1d.6xlarge": 192, "db.z1d.12xlarge": 384,
        "db.m7g.large": 16, "db.m7g.xlarge": 32, "db.m7g.2xlarge": 64, "db.m7g.4xlarge": 128, "db.m7g.8xlarge": 256, "db.m7g.12xlarge": 384, "db.m7g.16xlarge": 512,
        "db.r7g.large": 16, "db.r7g.xlarge": 32, "db.r7g.2xlarge": 64, "db.r7g.4xlarge": 128, "db.r7g.8xlarge": 256, "db.r7g.12xlarge": 384, "db.r7g.16xlarge": 512,
    }
    instance_type = db_instance['DBInstanceClass']
    memory_gb = instance_memory.get(instance_type, 1) # Padrão de 1 GB se não encontrado
    db_memory_bytes = memory_gb * 1024 * 1024 * 1024
    
    # A fórmula recomendada pelo RDS é GREATEST({log(DBInstanceClassMemory/81872)*1000}, {DBInstanceClassMemory/12582880})
    # Para simplificar, usamos a fórmula baseada em divisão, conforme seu script original
    max_connections = min(db_memory_bytes // 12582880, 12000)
    return int(max_connections)


def categorize_rds_instances():
    rds_client = boto3.client('rds', region_name=region)
    aurora_list = []
    rds_list = []
    aurora_serverless_list = []
    t_instance_list = []

    try:
        cluster_paginator = rds_client.get_paginator('describe_db_clusters')
        for page in cluster_paginator.paginate():
            for cluster in page['DBClusters']:
                cluster_id = cluster['DBClusterIdentifier']
                engine = cluster['Engine']
                engine_mode = cluster.get('EngineMode', '')
                if "aurora" in engine:
                    if engine_mode == "serverless":
                        aurora_serverless_list.append(cluster_id)
                    else:
                        aurora_list.append(cluster_id)
        
        instance_paginator = rds_client.get_paginator('describe_db_instances')
        for page in instance_paginator.paginate():
            for db_instance in page['DBInstances']:
                db_instance_id = db_instance['DBInstanceIdentifier']
                instance_type = db_instance['DBInstanceClass']

                if not db_instance.get('DBClusterIdentifier'): # Garante que não é uma instância de um cluster Aurora
                    # Dicionário de memória por tipo de instância (em GB)
                    instance_memory = {
                        "db.t3.micro": 1, "db.t3.small": 2, "db.t3.medium": 4, "db.t3.large": 8, "db.t3.xlarge": 16, "db.t3.2xlarge": 32,
                        "db.t4g.micro": 1, "db.t4g.small": 2, "db.t4g.medium": 4, "db.t4g.large": 8, "db.t4g.xlarge": 16, "db.t4g.2xlarge": 32,
                        "db.m5.large": 8, "db.m5.xlarge": 16, "db.m5.2xlarge": 32, "db.m5.4xlarge": 64, "db.m5.8xlarge": 128, "db.m5.12xlarge": 192, "db.m5.16xlarge": 256, "db.m5.24xlarge": 384,
                        "db.m6g.large": 8, "db.m6g.xlarge": 16, "db.m6g.2xlarge": 32, "db.m6g.4xlarge": 64, "db.m6g.8xlarge": 128, "db.m6g.12xlarge": 192, "db.m6g.16xlarge": 256,
                        "db.r5.large": 16, "db.r5.xlarge": 32, "db.r5.2xlarge": 64, "db.r5.4xlarge": 128, "db.r5.8xlarge": 256, "db.r5.12xlarge": 384, "db.r5.16xlarge": 512, "db.r5.24xlarge": 768,
                        "db.r6g.large": 16, "db.r6g.xlarge": 32, "db.r6g.2xlarge": 64, "db.r6g.4xlarge": 128, "db.r6g.8xlarge": 256, "db.r6g.12xlarge": 384, "db.r6g.16xlarge": 512,
                        "db.x1.16xlarge": 976, "db.x1.32xlarge": 1952,
                        "db.x2g.large": 16, "db.x2g.xlarge": 32, "db.x2g.2xlarge": 64, "db.x2g.4xlarge": 128, "db.x2g.8xlarge": 256, "db.x2g.12xlarge": 384, "db.x2g.16xlarge": 512,
                        "db.z1d.large": 16, "db.z1d.xlarge": 32, "db.z1d.2xlarge": 64, "db.z1d.3xlarge": 96, "db.z1d.6xlarge": 192, "db.z1d.12xlarge": 384,
                        "db.m7g.large": 16, "db.m7g.xlarge": 32, "db.m7g.2xlarge": 64, "db.m7g.4xlarge": 128, "db.m7g.8xlarge": 256, "db.m7g.12xlarge": 384, "db.m7g.16xlarge": 512,
                        "db.r7g.large": 16, "db.r7g.xlarge": 32, "db.r7g.2xlarge": 64, "db.r7g.4xlarge": 128, "db.r7g.8xlarge": 256, "db.r7g.12xlarge": 384, "db.r7g.16xlarge": 512,
                    }
                    
                    # Adiciona todas as instâncias não-aurora à lista T_instances com seus detalhes
                    max_connections = get_max_connections(db_instance)
                    memory_gb = instance_memory.get(instance_type, 8)
                    allocated_storage = db_instance.get('AllocatedStorage', 20)  # GB de armazenamento
                    t_instance_list.append({
                        "id": db_instance_id,
                        "type": instance_type,
                        "max_connections": max_connections,
                        "memory_gb": memory_gb,
                        "allocated_storage_gb": allocated_storage
                    })
                    
                    # Adiciona à lista 'RDS' apenas se não for da família 't'
                    if not instance_type.startswith('db.t'):
                        rds_list.append(db_instance_id)

        # Dicionário de memória por tipo de instância (em GB) - movido para dentro da função
        instance_memory = {
            "db.t3.micro": 1, "db.t3.small": 2, "db.t3.medium": 4, "db.t3.large": 8, "db.t3.xlarge": 16, "db.t3.2xlarge": 32,
            "db.t4g.micro": 1, "db.t4g.small": 2, "db.t4g.medium": 4, "db.t4g.large": 8, "db.t4g.xlarge": 16, "db.t4g.2xlarge": 32,
            "db.m5.large": 8, "db.m5.xlarge": 16, "db.m5.2xlarge": 32, "db.m5.4xlarge": 64, "db.m5.8xlarge": 128, "db.m5.12xlarge": 192, "db.m5.16xlarge": 256, "db.m5.24xlarge": 384,
            "db.m6g.large": 8, "db.m6g.xlarge": 16, "db.m6g.2xlarge": 32, "db.m6g.4xlarge": 64, "db.m6g.8xlarge": 128, "db.m6g.12xlarge": 192, "db.m6g.16xlarge": 256,
            "db.r5.large": 16, "db.r5.xlarge": 32, "db.r5.2xlarge": 64, "db.r5.4xlarge": 128, "db.r5.8xlarge": 256, "db.r5.12xlarge": 384, "db.r5.16xlarge": 512, "db.r5.24xlarge": 768,
            "db.r6g.large": 16, "db.r6g.xlarge": 32, "db.r6g.2xlarge": 64, "db.r6g.4xlarge": 128, "db.r6g.8xlarge": 256, "db.r6g.12xlarge": 384, "db.r6g.16xlarge": 512,
            "db.x1.16xlarge": 976, "db.x1.32xlarge": 1952,
            "db.x2g.large": 16, "db.x2g.xlarge": 32, "db.x2g.2xlarge": 64, "db.x2g.4xlarge": 128, "db.x2g.8xlarge": 256, "db.x2g.12xlarge": 384, "db.x2g.16xlarge": 512,
            "db.z1d.large": 16, "db.z1d.xlarge": 32, "db.z1d.2xlarge": 64, "db.z1d.3xlarge": 96, "db.z1d.6xlarge": 192, "db.z1d.12xlarge": 384,
            "db.m7g.large": 16, "db.m7g.xlarge": 32, "db.m7g.2xlarge": 64, "db.m7g.4xlarge": 128, "db.m7g.8xlarge": 256, "db.m7g.12xlarge": 384, "db.m7g.16xlarge": 512,
            "db.r7g.large": 16, "db.r7g.xlarge": 32, "db.r7g.2xlarge": 64, "db.r7g.4xlarge": 128, "db.r7g.8xlarge": 256, "db.r7g.12xlarge": 384, "db.r7g.16xlarge": 512,
        }

        # Criar lista com todas as instâncias RDS (incluindo não-T)
        all_rds_instances = t_instance_list.copy()
        for rds_id in rds_list:
            if not any(inst["id"] == rds_id for inst in t_instance_list):
                # Buscar informações da instância não-T
                for page in rds_client.get_paginator('describe_db_instances').paginate():
                    for db_instance in page['DBInstances']:
                        if db_instance['DBInstanceIdentifier'] == rds_id:
                            instance_type = db_instance['DBInstanceClass']
                            memory_gb = instance_memory.get(instance_type, 8)
                            max_connections = get_max_connections(db_instance)
                            allocated_storage = db_instance.get('AllocatedStorage', 20)  # GB de armazenamento
                            all_rds_instances.append({
                                "id": rds_id,
                                "type": instance_type,
                                "max_connections": max_connections,
                                "memory_gb": memory_gb,
                                "allocated_storage_gb": allocated_storage
                            })
                            break

        return {
            "Aurora_list": ", ".join(aurora_list),
            "RDS": ", ".join(rds_list),
            "Aurora_serverless_list": ", ".join(aurora_serverless_list),
            "T_instances": t_instance_list,
            "All_RDS_instances": all_rds_instances
        }
    
    except Exception as e:
        return {"error": f"Erro ao listar as instâncias RDS: {str(e)}"}


if __name__ == "__main__":
    categorized_rds = categorize_rds_instances()
    # Verifica se não houve erro antes de formatar o JSON
    if "error" not in categorized_rds:
        # A formatação do JSON para T_instances e All_RDS_instances é feita aqui
        categorized_rds["T_instances"] = json.dumps(categorized_rds.get("T_instances", []), indent=2)
        categorized_rds["All_RDS_instances"] = json.dumps(categorized_rds.get("All_RDS_instances", []), indent=2)
    
    # Imprime o dicionário final como uma string JSON
    print(json.dumps(categorized_rds, indent=4))