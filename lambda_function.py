import os
import json
import boto3
import traceback

def lambda_handler(event, context):
    try:
        # 1. On récupère l'ID de l'instance
        instance_id = os.environ.get('INSTANCE_ID', 'ID_INTROUVABLE')
        
        # 2. Connexion à EC2 (On laisse LocalStack gérer la bonne adresse réseau)
        endpoint = os.environ.get('AWS_ENDPOINT_URL')
        if endpoint:
            ec2 = boto3.client('ec2', endpoint_url=endpoint, region_name='us-east-1')
        else:
            ec2 = boto3.client('ec2', region_name='us-east-1')
        
        # 3. Quelle action est demandée dans l'URL ?
        action = "start"
        if event.get("queryStringParameters") and "action" in event["queryStringParameters"]:
            action = event["queryStringParameters"]["action"]
        
        # 4. On exécute l'ordre !
        if action == "stop":
            ec2.stop_instances(InstanceIds=[instance_id])
            message = f"Succès : L'instance {instance_id} a été ARRÊTÉE."
        else:
            ec2.start_instances(InstanceIds=[instance_id])
            message = f"Succès : L'instance {instance_id} a été DÉMARRÉE."

        return {
            "statusCode": 200,
            "body": json.dumps({"message": message})
        }
        
    except Exception as e:
        # En cas de crash, on force l'affichage du problème exact sur la page web !
        erreur_exacte = traceback.format_exc()
        return {
            "statusCode": 200, 
            "body": json.dumps({
                "message": "Aïe, le script a planté !", 
                "details": str(e),
                "trace": erreur_exacte
            })
        }