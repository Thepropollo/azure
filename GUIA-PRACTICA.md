# Guía de práctica: Despliegue de una app CRUD en Azure

## Objetivo

Montar una aplicación CRUD sencilla con:

- Backend en FastAPI
- Frontend estático en HTML + Tailwind
- API publicada en Azure App Service
- Frontend publicado en Azure Static Web Apps

## Estructura del proyecto

- `api.py`: API principal con FastAPI y SQLAlchemy
- `index.html`: frontend base
- `frontend/index.html`: frontend preparado para Static Web Apps
- `Dockerfile`: imagen de la API
- `azure-deploy.sh`: script de despliegue del backend

## Requisitos

- Python 3.11 o superior
- Docker
- Azure CLI (`az`)
- Una suscripción de Azure

## Arquitectura final

- Backend/API: [https://uleam-webapp.azurewebsites.net](https://uleam-webapp.azurewebsites.net)
- Frontend: [https://red-glacier-03b319e10.7.azurestaticapps.net](https://red-glacier-03b319e10.7.azurestaticapps.net)

El frontend consume la API pública usando la URL del backend.

## Ejecución local del backend

Para probar sin Azure SQL, usa SQLite:

```bash
cd /home/thepropollo/Videos/azure
USE_SQLITE=1 uvicorn api:app --host 0.0.0.0 --port 8000
```

Prueba rápida:

```bash
curl http://localhost:8000/
curl http://localhost:8000/tasks
```

## Ejecución local con Docker

Construir imagen:

```bash
cd /home/thepropollo/Videos/azure
docker build -t uleam-api:latest .
```

Ejecutar con SQLite:

```bash
docker run --rm -p 8000:8000 -e USE_SQLITE=1 --name uleam-api uleam-api:latest
```

## Frontend local

El frontend se encuentra en `frontend/index.html`. Para abrirlo en local:

```bash
cd /home/thepropollo/Videos/azure/frontend
python3 -m http.server 8080
```

Abre:

```text
http://localhost:8080
```

## Despliegue del backend en Azure

El script `azure-deploy.sh` crea los recursos necesarios y publica la imagen Docker.

```bash
cd /home/thepropollo/Videos/azure
chmod +x azure-deploy.sh
./azure-deploy.sh my-rg uleamacr uleam-webapp centralus
```

Después verifica:

```bash
curl https://uleam-webapp.azurewebsites.net/
curl https://uleam-webapp.azurewebsites.net/tasks
```

## Despliegue del frontend en Azure Static Web Apps

El frontend ya fue publicado en Azure Static Web Apps con la carpeta `frontend/`.

URL:

```text
https://red-glacier-03b319e10.7.azurestaticapps.net
```

## Qué aprendió esta práctica

- Cómo separar frontend y backend
- Cómo containerizar una API con Docker
- Cómo publicar una API en Azure App Service
- Cómo publicar un frontend estático en Azure Static Web Apps
- Cómo conectar el frontend con una API pública

## Problemas comunes

- Si la API da `503`, revisa los logs del App Service.
- Si el frontend no carga tareas, confirma que la URL de la API esté apuntando al backend público.
- Si usas Azure SQL, revisa credenciales, firewall y permisos.

## Cierre

Esta práctica ya quedó funcional en Azure y puede reutilizarse como base para otros equipos.