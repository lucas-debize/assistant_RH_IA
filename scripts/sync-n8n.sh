#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/lib/load-env.sh"

cd "$PROJECT_DIR"
load_env_file ".env"

echo "=== Mise à jour depuis .env ==="

python3 "$SCRIPT_DIR/generate-config.py"

until docker compose exec -T postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; do
  sleep 2
done

docker compose run --rm n8n-import import:credentials --input=/config/credentials.json
docker compose run --rm n8n-import import:workflow --input=/config/workflow.json
"$SCRIPT_DIR/fix-n8n-workflows.sh"

echo ""
echo "✅ Config mise à jour → http://localhost:${N8N_PORT:-5678}"
