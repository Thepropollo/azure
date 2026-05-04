#!/usr/bin/env bash
set -euo pipefail

# Script para crear Azure Container Registry (ACR) y mostrar credenciales.
# Uso: ./azure_acr.sh <RG> <LOCATION> <ACR_NAME>

if [ "$#" -lt 3 ]; then
  echo "Uso: $0 <RG> <LOCATION> <ACR_NAME>"
  exit 1
fi

RG=$1
LOCATION=$2
ACR_NAME=$3

command -v az >/dev/null 2>&1 || { echo "az CLI no encontrado. Instala y vuelve a ejecutar."; exit 1; }

az group create -n "$RG" -l "$LOCATION"

echo "Creando ACR: $ACR_NAME"
az acr create -n "$ACR_NAME" -g "$RG" --sku Basic --location "$LOCATION"

LOGIN_SERVER=$(az acr show -n "$ACR_NAME" -g "$RG" --query loginServer -o tsv)

echo "ACR creado: $LOGIN_SERVER"

echo "Obteniendo credenciales del registro (usadas en GitHub Secrets)"
az acr credential show -n "$ACR_NAME" -g "$RG" --query "{username:username,password:passwords[0].value}" -o json

echo "Ejemplo de variables para GitHub Secrets:
- ACR_LOGIN_SERVER: $LOGIN_SERVER
- ACR_USERNAME: <username from above>
- ACR_PASSWORD: <password from above>"

echo "Si vas a usar 'az acr build' en GitHub Actions, asegúrate de que el Service Principal (AZURE_CREDENTIALS) tenga permisos sobre el resource group o ACR." 

echo "Listo."
