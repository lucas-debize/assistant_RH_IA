#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
# shellcheck source=lib/load-env.sh
source "$SCRIPT_DIR/lib/load-env.sh"

cd "$PROJECT_DIR"

echo "╔══════════════════════════════════════════════╗"
echo "║     Assistant RH IA - Démarrage complet      ║"
echo "╚══════════════════════════════════════════════╝"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo ""
  echo "⚠️  Fichier .env créé. Éditez-le avec vos identifiants Gmail, puis relancez :"
  echo "    ./scripts/setup.sh"
  exit 0
fi

load_env_file ".env"

echo ""
echo "→ Génération config n8n depuis .env..."
python3 "$SCRIPT_DIR/generate-config.py"

echo ""
echo "→ Démarrage Docker (postgres, n8n, ollama, pdf-extractor)..."
docker compose up -d --build

echo ""
echo "→ Attente PostgreSQL..."
until docker compose exec -T postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; do
  sleep 2
done

echo ""
echo "→ Import credentials + workflow dans n8n..."
docker compose run --rm n8n-import import:credentials --input=/config/credentials.json
docker compose run --rm n8n-import import:workflow --input=/config/workflow.json

echo ""
echo "→ Publication + activation du workflow..."
"$SCRIPT_DIR/fix-n8n-workflows.sh"

echo ""
echo "→ Téléchargement modèle Ollama ($OLLAMA_MODEL)..."
docker compose exec -T ollama ollama pull "$OLLAMA_MODEL" 2>/dev/null || \
  docker compose exec -T ollama ollama pull mistral

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║              ✅ Tout est prêt !               ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  n8n      → http://localhost:${N8N_PORT}  (créer le compte admin au 1er lancement)"
echo "  Workflow → Assistant RH IA - Traitement candidatures (ACTIF, déclencheur IMAP)"
echo ""
echo "  Test : envoyez un email avec PDF à ${IMAP_USER}"
echo "         → notification sur ${RECRUITER_EMAIL} en quelques secondes"
echo ""
echo "  Modifier .env plus tard → ./scripts/sync-n8n.sh"
echo "  Arrêter                 → docker compose down"
echo ""
