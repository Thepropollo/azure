#!/usr/bin/env bash
set -euo pipefail

# Uso: ./azure-deploy.sh <RESOURCE_GROUP> <ACR_NAME> <APP_NAME> <LOCATION>
# Ejemplo: ./azure-deploy.sh my-rg uleamacr uleam-webapp centralus

RG=${1:-myResourceGroup}
ACR_NAME=${2:-uleamacr}
APP_NAME=${3:-uleam-webapp}
LOCATION=${4:-centralus}
IMAGE_NAME=${ACR_NAME}.azurecr.io/uleam-api:latest

echo "1) Inicia sesión en Azure (si no lo has hecho): az login"
echo "2) Crear resource group si no existe"
az group create -n "$RG" -l "$LOCATION"

echo "3) Crear Azure Container Registry (si no existe)"
az acr create -n "$ACR_NAME" -g "$RG" --sku Basic --admin-enabled true

ACR_LOGIN_SERVER=$(az acr show -n "$ACR_NAME" -g "$RG" --query loginServer -o tsv)
ACR_USERNAME=$(az acr credential show -n "$ACR_NAME" -g "$RG" --query username -o tsv)
ACR_PASSWORD=$(az acr credential show -n "$ACR_NAME" -g "$RG" --query passwords[0].value -o tsv)

echo "4) Loguear Docker en ACR"
echo "$ACR_PASSWORD" | docker login "$ACR_LOGIN_SERVER" -u "$ACR_USERNAME" --password-stdin

echo "5) Tag y push de la imagen local al ACR"
docker tag uleam-api:latest "$IMAGE_NAME"
docker push "$IMAGE_NAME"

echo "6) Crear App Service Plan (Linux)"
az appservice plan create -g "$RG" -n "${APP_NAME}-plan" --is-linux --sku B1

echo "7) Crear Web App for Containers apuntando al ACR image"
az webapp create -g "$RG" -p "${APP_NAME}-plan" -n "$APP_NAME" --deployment-container-image-name "$IMAGE_NAME"

echo "7.1) Configurar el contenedor privado y el puerto correcto"
az webapp config container set -g "$RG" -n "$APP_NAME" \
  --docker-custom-image-name "$IMAGE_NAME" \
  --docker-registry-server-url "https://$ACR_LOGIN_SERVER" \
  --docker-registry-server-user "$ACR_USERNAME" \
  --docker-registry-server-password "$ACR_PASSWORD"

echo "8) Configurar variables de entorno (App Settings) - ACTUALIZA valores"
az webapp config appsettings set -g "$RG" -n "$APP_NAME" --settings \
  DB_SERVER=sql-server-thepropollo.database.windows.net \
  DB_NAME=crud-db \
  DB_USER=azureuser \
  DB_PASS=TuPasswordPro123! \
  WEBSITES_PORT=8000 \
  WEBSITES_ENABLE_APP_SERVICE_STORAGE=false

echo "9) Mostrar URL de la app"
az webapp show -g "$RG" -n "$APP_NAME" --query defaultHostName -o tsv

echo "Despliegue completado (espera unos minutos para que la app esté lista)."
