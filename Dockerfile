FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive

# Dependencias del sistema para pyodbc + driver ODBC de Microsoft
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       curl \
       gnupg \
       apt-transport-https \
       ca-certificates \
       unixodbc-dev \
    && rm -rf /var/lib/apt/lists/*

# Agregar repositorio de Microsoft e instalar msodbcsql17
RUN mkdir -p /usr/share/keyrings \
    && curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft.gpg \
    && curl -sSL https://packages.microsoft.com/config/debian/12/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && sed -i 's|/usr/share/keyrings/microsoft-prod.gpg|/usr/share/keyrings/microsoft.gpg|g' /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql17 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Instalar dependencias Python
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copiar código
COPY . /app

EXPOSE 8000

CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"]
