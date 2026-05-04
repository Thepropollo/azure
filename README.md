# API Gestión de Inventario — FastAPI (nivel base)

Proyecto ejemplo: backend en FastAPI desplegable en Azure App Service con PostgreSQL y Azure Key Vault.

Contenido:
- `app/` : código FastAPI
- `Dockerfile` : imagen para despliegue
- `.github/workflows/deploy.yml` : ejemplo CI/CD para Azure
- `azure-deploy.md` : pasos para crear recursos Azure y vincular Key Vault

Rápido inicio (local):

1. Copiar `.env.example` a `.env` y ajustar `DATABASE_URL`.
2. Instalar dependencias:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

3. Ejecutar la app:

```bash
export DATABASE_URL="postgresql+psycopg2://user:pass@localhost:5432/inventory"
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Azure / Key Vault: ver `azure-deploy.md` para pasos resumidos sobre Key Vault, Managed Identity y App Service.
