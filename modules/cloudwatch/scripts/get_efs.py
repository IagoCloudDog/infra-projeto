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

def get_efs_instances():
    efs_client = boto3.client('efs', region_name=region)
    efs_list = []

    try:
        # Buscar File Systems EFS
        paginator = efs_client.get_paginator('describe_file_systems')
        for page in paginator.paginate():
            for file_system in page['FileSystems']:
                efs_id = file_system['FileSystemId']
                efs_list.append(efs_id)

        return {
            "EFS_list": ", ".join(efs_list)
        }
    
    except Exception as e:
        return {"error": f"Erro ao listar os sistemas de arquivos EFS: {str(e)}"}

if __name__ == "__main__":
    efs_data = get_efs_instances()
    print(json.dumps(efs_data, indent=4))