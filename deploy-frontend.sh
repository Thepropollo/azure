#!/usr/bin/env bash
set -euo pipefail

# Uso: ./deploy-frontend.sh <RESOURCE_GROUP> <STATIC_WEB_APP_NAME> [FRONTEND_DIR]
# Ejemplo: ./deploy-frontend.sh practica-estudiante uleamfrontpractica frontend

RG=${1:-practica-estudiante}
SWA_NAME=${2:-uleamfrontpractica}
FRONTEND_DIR=${3:-frontend}

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI no está instalado o no está en PATH." >&2
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "npx no está disponible. Instala Node.js para poder publicar el frontend." >&2
  exit 1
fi

if [ ! -d "$FRONTEND_DIR" ]; then
  echo "No existe la carpeta del frontend: $FRONTEND_DIR" >&2
  exit 1
fi

echo "Obteniendo token de despliegue para $SWA_NAME en $RG..."
DEPLOY_TOKEN=$(az staticwebapp secrets list -n "$SWA_NAME" -g "$RG" --query properties.apiKey -o tsv)

if [ -z "$DEPLOY_TOKEN" ]; then
  echo "No se pudo obtener el token de despliegue." >&2
  exit 1
fi

echo "Publicando frontend desde $FRONTEND_DIR..."
npx --yes @azure/static-web-apps-cli deploy "$FRONTEND_DIR" --deployment-token "$DEPLOY_TOKEN" --env production
