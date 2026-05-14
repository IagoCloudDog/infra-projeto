import boto3
import hcl2
import json
import glob
import sys

# Procura por arquivo .tfvars
tfvars_files = glob.glob('./*.tfvars')

if not tfvars_files:
    print(json.dumps({"error": "Nenhum arquivo .tfvars foi encontrado no diretório atual."}))
    sys.exit(1)

tfvars_file_path = tfvars_files[0]

try:
    with open(tfvars_file_path, "r") as tfvars_file:
        tfvars = hcl2.load(tfvars_file)
except Exception as e:
    print(json.dumps({"error": f"Erro ao ler ou analisar o arquivo {tfvars_file_path}: {e}"}))
    sys.exit(1)

region = tfvars.get("region")

if not region:
    print(json.dumps({"error": f"A variável 'region' não foi encontrada dentro de {tfvars_file_path}."}))
    sys.exit(1)

def get_redis_instances():
    elasticache_client = boto3.client('elasticache', region_name=region)
    redis_list = []
    cache_cluster_map = {}

    try:
        # Buscar Cache Clusters (Redis nodes)
        paginator = elasticache_client.get_paginator('describe_cache_clusters')
        for page in paginator.paginate():
            for cluster in page['CacheClusters']:
                if cluster['Engine'] in ['redis', 'valkey']:
                    cluster_id = cluster['CacheClusterId']
                    # Verificar se é um nó primário (terminando com -001)
                    if cluster_id.endswith('-001'):
                        base_name = cluster_id[:-4]  # Remove o -001
                        redis_list.append(cluster_id)
                        cache_cluster_map[base_name] = cluster_id

        return {
            "Redis_list": ", ".join(redis_list),
            "Cache_cluster_map": json.dumps(cache_cluster_map)
        }
    
    except Exception as e:
        return {"error": f"Erro ao listar as instâncias Redis: {str(e)}"}

if __name__ == "__main__":
    redis_data = get_redis_instances()
    print(json.dumps(redis_data, indent=4))