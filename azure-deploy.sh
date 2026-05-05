#!/usr/bin/env bash
set -euo pipefail

# Uso: ./azure-deploy.sh <RESOURCE_GROUP> <ACR_NAME> <APP_NAME> <LOCATION>
# Ejemplo: ./azure-deploy.sh my-rg uleamacr uleam-webapp centralus

RG=${1:-myResourceGroup}
# ACR names must be 5-50 chars, lowercase letters and numbers only (no dashes).
RAW_ACR_NAME=${2:-uleamacr}
ACR_NAME_SANITIZED=$(echo "$RAW_ACR_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')
# Ensure minimum length 5
if [ ${#ACR_NAME_SANITIZED} -lt 5 ]; then
  SUFFIX=$(head -c 8 /dev/urandom | tr -dc 'a-z0-9' | cut -c1-5)
  ACR_NAME_SANITIZED="${ACR_NAME_SANITIZED}${SUFFIX}"
fi
if [ "$ACR_NAME_SANITIZED" != "$RAW_ACR_NAME" ]; then
  echo "Aviso: el nombre de ACR '$RAW_ACR_NAME' contiene caracteres inválidos; usando '$ACR_NAME_SANITIZED' en su lugar."
fi
ACR_NAME=${ACR_NAME_SANITIZED}
APP_NAME=${3:-uleam-webapp}
LOCATION=${4:-centralus}
IMAGE_NAME=${ACR_NAME}.azurecr.io/uleam-api:latest
PLAN_NAME=${PLAN_NAME:-${APP_NAME}-plan}
PLAN_CREATE_RETRIES=${PLAN_CREATE_RETRIES:-6}
PLAN_CREATE_DELAY=${PLAN_CREATE_DELAY:-20}

retry_plan_create() {
  local attempt=1
  local delay="$PLAN_CREATE_DELAY"

  while true; do
    if az appservice plan create -g "$RG" -n "$PLAN_NAME" --is-linux --sku B1; then
      return 0
    fi

    if [[ "$attempt" -ge "$PLAN_CREATE_RETRIES" ]]; then
      echo "No se pudo crear el App Service Plan tras $PLAN_CREATE_RETRIES intentos." >&2
      return 1
    fi

    echo "App Service Plan throttled o falló. Reintentando en ${delay}s (${attempt}/${PLAN_CREATE_RETRIES})..." >&2
    sleep "$delay"
    attempt=$((attempt + 1))
    delay=$((delay * 2))
  done
}

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

echo "6) Crear o reutilizar App Service Plan (Linux)"
if az appservice plan show -g "$RG" -n "$PLAN_NAME" >/dev/null 2>&1; then
  echo "   Usando App Service Plan existente: $PLAN_NAME"
else
  echo "   Creando App Service Plan: $PLAN_NAME"
  retry_plan_create
fi

echo "7) Crear Web App for Containers apuntando al ACR image"
az webapp create -g "$RG" -p "$PLAN_NAME" -n "$APP_NAME" --deployment-container-image-name "$IMAGE_NAME"

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
