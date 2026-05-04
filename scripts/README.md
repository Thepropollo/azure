Scripts para provisionar recursos Azure

azure_provision.sh
- Propósito: crear Resource Group, PostgreSQL Flexible Server, base de datos y Key Vault, y almacenar `DATABASE_URL` en Key Vault.
- Requisitos: `az` CLI, estar autenticado (az login) y permisos para crear recursos.
- Uso:

```bash
chmod +x scripts/azure_provision.sh
./scripts/azure_provision.sh rg-inventory westeurope pg-inventory myadmin "<password>" inventory kv-inventory <YOUR_PUBLIC_IP>
```

Notas:
- Para producción, reemplaza la contraseña por un secreto seguro o mecanismo de provisión de claves.
- Considera habilitar Private Endpoint y reglas de red más estrictas.
- El script no crea App Service ni asigna identities; esos pasos están en `azure-deploy.md`.

azure_acr.sh
- Propósito: crear Azure Container Registry (ACR) y mostrar credenciales.
- Requisitos: `az` CLI, estar autenticado (az login) y permisos para crear recursos.
- Uso:

```bash
chmod +x scripts/azure_acr.sh
./scripts/azure_acr.sh rg-inventory westeurope myacrname
```

Notas adicionales:
- El script muestra el `loginServer` y las credenciales (usuario/contraseña) que puedes copiar como `ACR_LOGIN_SERVER`, `ACR_USERNAME` y `ACR_PASSWORD` a los GitHub Secrets.
- En GitHub Actions el workflow usa esos secrets para hacer `docker push` al ACR y luego despliega la imagen en App Service.
