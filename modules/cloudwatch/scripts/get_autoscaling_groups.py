#!/usr/bin/env python3
import boto3
import json
import sys

def get_autoscaling_groups():
    try:
        # Tenta diferentes formas de obter credenciais
        session = boto3.Session()
        client = session.client('autoscaling')
        
        response = client.describe_auto_scaling_groups()
        asg_names = [asg['AutoScalingGroupName'] for asg in response['AutoScalingGroups']]
        
        return {name: name for name in asg_names}
    
    except Exception as e:
        # Para debug, você pode descomentar a linha abaixo
        # print(f"Error: {str(e)}", file=sys.stderr)
        # Retorna dicionário vazio se não conseguir acessar a API
        return {}

if __name__ == "__main__":
    result = get_autoscaling_groups()
    print(json.dumps(result))