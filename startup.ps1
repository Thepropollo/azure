<#
Usage (PowerShell):
# From project root:
#   $env:USE_SQLITE = "1"; ./startup.ps1
# Or to set port:
#   $env:PORT = "8000"; ./startup.ps1
# Ensure Python and uvicorn are installed in the active environment.
# If using Windows and virtualenv:
#   python -m venv .venv
#   .\.venv\Scripts\Activate.ps1
#   pip install -r requirements.txt
#
# This script starts the API similarly to startup.sh on Linux/macOS.
#>

if ($env:USE_SQLITE -eq "1") {
    Write-Host "Arrancando FastAPI con SQLite (USE_SQLITE=1) en el puerto ${env:PORT:-8000}"
} else {
    Write-Host "Arrancando FastAPI (usar variables DB_* en entorno) en el puerto ${env:PORT:-8000}"
}

if ($env:PORT) {
    python -m uvicorn api:app --host 0.0.0.0 --port $env:PORT
} else {
    python -m uvicorn api:app --host 0.0.0.0 --port 8000
}
