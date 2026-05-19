#!/bin/bash

export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"
export ENDPOINT="http://localhost:4566"

echo "⏳ 1. Recherche d'une image système (AMI) dans LocalStack..."
# On demande à LocalStack de nous donner un ID d'image valide
AMI_ID=$(aws --endpoint-url=$ENDPOINT ec2 describe-images --query 'Images[0].ImageId' --output text)
echo "✅ Image trouvée : $AMI_ID"

echo "⏳ 2. Création du serveur EC2 fictif..."
INSTANCE_ID=$(aws --endpoint-url=$ENDPOINT ec2 run-instances --image-id $AMI_ID --count 1 --instance-type t2.micro --query 'Instances[0].InstanceId' --output text)

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
    echo "❌ Erreur : Impossible de créer l'instance EC2. Arrêt du script."
    exit 1
fi
echo "✅ Instance EC2 créée avec l'ID : $INSTANCE_ID"

echo "⏳ 3. Préparation du code Lambda..."
zip function.zip lambda_function.py > /dev/null

echo "⏳ 4. Création des droits d'accès (Rôle IAM)..."
aws --endpoint-url=$ENDPOINT iam create-role --role-name lambda-role --assume-role-policy-document '{"Statement": [{"Action": "sts:AssumeRole", "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}}]}' > /dev/null 2>&1

echo "⏳ 5. Déploiement de la fonction Lambda..."
aws --endpoint-url=$ENDPOINT lambda delete-function --function-name PiloteEC2 > /dev/null 2>&1

aws --endpoint-url=$ENDPOINT lambda create-function \
    --function-name PiloteEC2 \
    --zip-file fileb://function.zip \
    --handler lambda_function.lambda_handler \
    --runtime python3.9 \
    --role arn:aws:iam::000000000000:role/lambda-role \
    --environment "Variables={INSTANCE_ID=$INSTANCE_ID}" > /dev/null
echo "✅ Fonction Lambda 'PiloteEC2' déployée."

echo "⏳ 6. Création de la porte d'entrée web (API Gateway)..."
API_ID=$(aws --endpoint-url=$ENDPOINT apigateway create-rest-api --name 'MonAPI' --query 'id' --output text)
PARENT_ID=$(aws --endpoint-url=$ENDPOINT apigateway get-resources --rest-api-id $API_ID --query 'items[0].id' --output text)

aws --endpoint-url=$ENDPOINT apigateway put-method --rest-api-id $API_ID --resource-id $PARENT_ID --http-method GET --authorization-type "NONE" > /dev/null
aws --endpoint-url=$ENDPOINT apigateway put-integration --rest-api-id $API_ID --resource-id $PARENT_ID --http-method GET --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:PiloteEC2/invocations > /dev/null
aws --endpoint-url=$ENDPOINT apigateway create-deployment --rest-api-id $API_ID --stage-name prod > /dev/null

echo "========================================================"
echo "🎉 DEPLOIEMENT TERMINE AVEC SUCCES !"

# On remplace localhost par l'URL publique de votre Codespace pour l'affichage
PUBLIC_URL="https://cuddly-goldfish-wrgj4pgjw4pr25p9w-4566.app.github.dev"

echo "Voici l'URL de votre API Gateway (pour DÉMARRER l'EC2) :"
echo "$PUBLIC_URL/restapis/$API_ID/prod/_user_request_/?action=start"
echo ""
echo "Voici l'URL de votre API Gateway (pour ARRÊTER l'EC2) :"
echo "$PUBLIC_URL/restapis/$API_ID/prod/_user_request_/?action=stop"
echo "========================================================"