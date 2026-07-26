$ErrorActionPreference = "Stop"
$ProjectDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $ProjectDir

Write-Host "=== Mise à jour depuis .env ==="

python scripts/generate-config.py

Write-Host ""
Write-Host "Attente PostgreSQL..."
do {
    Start-Sleep -Seconds 2
    docker compose exec -T postgres pg_isready 2>$null
} while ($LASTEXITCODE -ne 0)

docker compose run --rm n8n-import import:credentials --input=/config/credentials.json
docker compose run --rm n8n-import import:workflow --input=/config/workflow.json
bash scripts/fix-n8n-workflows.sh

Write-Host ""
Write-Host "✅ Config mise à jour → http://localhost:5678"
