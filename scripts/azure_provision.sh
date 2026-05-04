#!/usr/bin/env bash
set -euo pipefail

# Script para provisionar Resource Group, PostgreSQL Flexible Server, DB y Key Vault.
# Uso: ./azure_provision.sh <RG> <LOCATION> <PG_NAME> <ADMIN_USER> <ADMIN_PASSWORD> <DB_NAME> <KV_NAME>

if [ "$#" -lt 7 ]; then
  echo "Uso: $0 <RG> <LOCATION> <PG_NAME> <ADMIN_USER> <ADMIN_PASSWORD> <DB_NAME> <KV_NAME> [ALLOW_IP]"
  exit 1
fi

RG=$1
LOCATION=$2
PG_NAME=$3
ADMIN_USER=$4
ADMIN_PASS=$5
DB_NAME=$6
KV_NAME=$7
ALLOW_IP=${8-}

command -v az >/dev/null 2>&1 || { echo "az CLI no encontrado. Instala y vuelve a ejecutar."; exit 1; }

echo "Autenticando a Azure (si es necesario)..."
az account show >/dev/null 2>&1 || az login

echo "Creando resource group: $RG ($LOCATION)"
az group create -n "$RG" -l "$LOCATION"

echo "Creando PostgreSQL flexible server: $PG_NAME"
az postgres flexible-server create -g "$RG" -n "$PG_NAME" --admin-user "$ADMIN_USER" --admin-password "$ADMIN_PASS" --location "$LOCATION" --sku-name Standard_B1ms

echo "Creando base de datos: $DB_NAME"
az postgres flexible-server db create -g "$RG" -s "$PG_NAME" -d "$DB_NAME"

if [ -n "$ALLOW_IP" ]; then
  echo "Añadiendo regla de firewall para IP: $ALLOW_IP"
  az postgres flexible-server firewall-rule create -g "$RG" -s "$PG_NAME" -n allow_client_ip --start-ip-address "$ALLOW_IP" --end-ip-address "$ALLOW_IP"
else
  echo "No se indicó IP. Para accesos desde el cliente local, añade una regla de firewall manualmente."
fi

# Construir connection string en formato SQLAlchemy/psycopg2
CONN_STR="postgresql+psycopg2://${ADMIN_USER}:${ADMIN_PASS}@${PG_NAME}.postgres.database.azure.com:5432/${DB_NAME}"

echo "Creando Key Vault: $KV_NAME"
az keyvault create -g "$RG" -n "$KV_NAME" --location "$LOCATION"

echo "Guardando secreto DATABASE_URL en Key Vault"
az keyvault secret set --vault-name "$KV_NAME" --name DATABASE_URL --value "$CONN_STR"

echo "Resultado: SecretUri:"
az keyvault secret show --vault-name "$KV_NAME" --name DATABASE_URL --query id -o tsv

echo "Provisionamiento completado. Revisa reglas de firewall y considera Private Endpoint para producción."
