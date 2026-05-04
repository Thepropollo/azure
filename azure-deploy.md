# Despliegue en Azure — pasos resumidos

1) Crear recursos básicos

- Crear Resource Group:

```bash
az group create -n rg-inventory -l westeurope
```

- Crear Azure Database for PostgreSQL (Single Server o Flexible Server recomendado):

```bash
az postgres flexible-server create -g rg-inventory -n pg-inventory --admin-user myadmin --admin-password "<password>" --location westeurope --sku-name Standard_B1ms
az postgres flexible-server db create -g rg-inventory -n pg-inventory -d inventory
```

Asegúrate de configurar reglas de firewall o VNet según tu escenario.

2) Crear Azure Key Vault y almacenar el connection string

```bash
az keyvault create -g rg-inventory -n kv-inventory --location westeurope
az keyvault secret set --vault-name kv-inventory --name DATABASE_URL --value "postgresql+psycopg2://myadmin:<password>@pg-inventory.postgres.database.azure.com:5432/inventory"
```

3) Crear App Service (Web App for Containers) y habilitar Managed Identity

- Crear Plan y Web App:

```bash
az appservice plan create -g rg-inventory -n plan-inventory --is-linux --sku B1
az webapp create -g rg-inventory -p plan-inventory -n my-inventory-app --deployment-container-image-name myregistry.azurecr.io/inventory:latest
```

- Habilitar System-assigned identity:

```bash
az webapp identity assign -g rg-inventory -n my-inventory-app
```

4) Dar permiso al Managed Identity para leer secretos del Key Vault

- Obtener principalId del webapp y asignar acceso basado en RBAC (secrets user):

```bash
PRINCIPAL_ID=$(az webapp identity show -g rg-inventory -n my-inventory-app --query principalId -o tsv)
az role assignment create --role "Key Vault Secrets User" --assignee $PRINCIPAL_ID --scope $(az keyvault show -n kv-inventory -g rg-inventory --query id -o tsv)
```

5) Configurar Key Vault Reference en Application Settings (App Service)

- En lugar de poner la cadena en texto, usar la referencia de Key Vault:

En Application settings de App Service añade una variable `DATABASE_URL` con valor:

```
@Microsoft.KeyVault(SecretUri=https://kv-inventory.vault.azure.net/secrets/DATABASE_URL/)
```

App Service resolverá el secreto usando la identidad asignada.

6) Despliegue desde GitHub Actions

- Configura el workflow `.github/workflows/deploy.yml` y los secrets de repositorio: `AZURE_CREDENTIALS` (JSON de un Service Principal o usar Azure Login con OIDC), `AZURE_WEBAPP_NAME`.

7) Notas de seguridad y operativo

- No guardar secretos en el repo.
- Para entornos productivos, usa redes privadas, VNet-integration y reglas de acceso restringidas en PostgreSQL y Key Vault.
- Considera usar Private Endpoint para Key Vault y PostgreSQL en producción.
