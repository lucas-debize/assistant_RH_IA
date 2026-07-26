#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
# shellcheck source=lib/load-env.sh
source "$SCRIPT_DIR/lib/load-env.sh"

cd "$PROJECT_DIR"
load_env_file ".env"

WORKFLOW_ID="b2c3d4e5-0001-4000-8000-000000000001"
WORKFLOW_NAME="Assistant RH IA - Traitement candidatures"

echo "→ Nettoyage doublons..."
docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<SQL
DELETE FROM shared_workflow
WHERE "workflowId" IN (
  SELECT id FROM workflow_entity
  WHERE id <> '${WORKFLOW_ID}'
    AND (name = '${WORKFLOW_NAME}' OR name IN ('Assistant RH IA', 'New_workflow'))
);
DELETE FROM workflow_history
WHERE "workflowId" IN (
  SELECT id FROM workflow_entity
  WHERE id <> '${WORKFLOW_ID}'
    AND (name = '${WORKFLOW_NAME}' OR name IN ('Assistant RH IA', 'New_workflow'))
);
DELETE FROM workflow_entity
WHERE id <> '${WORKFLOW_ID}'
  AND (name = '${WORKFLOW_NAME}' OR name IN ('Assistant RH IA', 'New_workflow'));

UPDATE workflow_entity
SET "isArchived" = false, active = true
WHERE id = '${WORKFLOW_ID}';
SQL

echo "→ Publication du workflow..."
docker compose run --rm n8n-import publish:workflow --id="${WORKFLOW_ID}"

echo "→ Redémarrage n8n..."
docker compose restart n8n

echo "✅ Workflow publié et actif : « ${WORKFLOW_NAME} »"
