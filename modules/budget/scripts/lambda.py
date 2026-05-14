import os
import re
import json
import boto3

sns_client = boto3.client('sns')

# Tópico de destino para as mensagens processadas
processed_topic_arn = os.environ['SNS_PROCESSED_TOPIC_ARN']

def lambda_handler(event, context):
    print("Lambda invoked by the budget SNS topic")

    # Variáveis de ambiente
    customer_name = os.getenv('CUSTOMER_NAME')
    account_id = os.getenv('ACCOUNT_ID')
    daily_budget_value = os.getenv('DAILY_BUDGET_VALUE')  
    monthly_budget_value = os.getenv('MONTHLY_BUDGET_VALUE')  
    
    try:
        # Pega a mensagem recebida no SNS
        sns_message = event['Records'][0]['Sns']['Message']
        sns_subject = event['Records'][0]['Sns'].get('Subject', 'No Subject')

        # Faz parsing da mensagem original do Budget
        budget_name_match = re.search(r'Budget Name: (\S+)', sns_message)
        actual_cost_match = re.search(r'ACTUAL Amount: (\S+)', sns_message)
        expected_cost_match = re.search(r'Alert Threshold: > (\S+)', sns_message)
        
        if budget_name_match:
            budget_name = budget_name_match.group(1)
        else:
            budget_name = f"{customer_name}_{account_id}_DAILY_OR_MONTHLY"
        
        actual_cost = actual_cost_match.group(1) if actual_cost_match else "N/A"
        expected_cost = expected_cost_match.group(1) if expected_cost_match else "N/A"

        # Gera a nova mensagem formatada
        custom_message = generate_message(budget_name, expected_cost, actual_cost)
        custom_subject = f"[Budget Alert] {budget_name}"

        # Publica no tópico processado
        send_sns_message(processed_topic_arn, custom_message, custom_subject)

        return generate_response('Success', 200, 'Message forwarded successfully')
    
    except KeyError as e:
        print(f"Error processing SNS message: {str(e)}")
        return generate_response('Error', 500, f'Error processing SNS message: {str(e)}')
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON: {str(e)}")
        return generate_response('Error', 500, f'Error decoding JSON: {str(e)}')

def send_sns_message(topic_arn, message, subject):
    sns_client.publish(
        TopicArn=topic_arn,
        Message=message,
        Subject=subject,
        MessageAttributes={
            'eventType': {
                'DataType': 'String',
                'StringValue': 'create'
            }
        }
    )

def generate_message(budget_name, expected_cost, actual_cost):
    message = f"Nome do cliente: {os.getenv('CUSTOMER_NAME')}\n"
    message += f"Id da conta: {os.getenv('ACCOUNT_ID')}\n"
    message += f"Orçamento: {budget_name}\n"
    message += f"Custo esperado: {expected_cost}\n"
    message += f"Custo atual: {actual_cost}\n"
    message += f"Por favor, verifique se não há alguma anomalia na conta."
    return message

def generate_response(status, code=None, message=None):
    return {
        'status': status,
        'code': code,
        'message': message
    }