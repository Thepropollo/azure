#!/usr/bin/env bash
set -euo pipefail

# Usage: USE_SQLITE=1 PORT=8000 ./startup.sh
: "${USE_SQLITE:=0}"
: "${PORT:=8000}"

if [ "$USE_SQLITE" = "1" ]; then
	echo "Arrancando FastAPI con SQLite (USE_SQLITE=1) en el puerto $PORT"
else
	echo "Arrancando FastAPI (usar variables DB_* en entorno) en el puerto $PORT"
fi

exec uvicorn api:app --host 0.0.0.0 --port "$PORT"
