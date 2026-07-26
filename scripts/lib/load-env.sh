#!/usr/bin/env bash
set -euo pipefail

load_env_file() {
  local env_file="${1:-.env}"

  if [[ ! -f "$env_file" ]]; then
    echo "❌ Fichier $env_file introuvable. Copiez .env.example vers .env" >&2
    exit 1
  fi

  if grep -q $'\r' "$env_file" 2>/dev/null; then
    sed -i 's/\r$//' "$env_file"
  fi

  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a

  if [[ -n "${IMAP_PASSWORD:-}" ]]; then
    IMAP_PASSWORD="$(echo "$IMAP_PASSWORD" | tr -d ' ')"
    export IMAP_PASSWORD
  fi
  if [[ -n "${SMTP_PASSWORD:-}" ]]; then
    SMTP_PASSWORD="$(echo "$SMTP_PASSWORD" | tr -d ' ')"
    export SMTP_PASSWORD
  fi

  export IMAP_PORT="${IMAP_PORT:-993}"
  export IMAP_MAILBOX="${IMAP_MAILBOX:-INBOX}"
  export SMTP_PORT="${SMTP_PORT:-587}"
  export OLLAMA_MODEL="${OLLAMA_MODEL:-mistral}"
  export OLLAMA_PORT="${OLLAMA_PORT:-11434}"
  export PDF_EXTRACTOR_PORT="${PDF_EXTRACTOR_PORT:-8080}"
  export N8N_PORT="${N8N_PORT:-5678}"
  export N8N_HOST="${N8N_HOST:-localhost}"
  export TIMEZONE="${TIMEZONE:-Europe/Paris}"
  export POSTGRES_PORT="${POSTGRES_PORT:-5432}"
  export RH_DB_HOST="${RH_DB_HOST:-postgres}"
  export RH_DB_PORT="${RH_DB_PORT:-5432}"
  export OLLAMA_URL="${OLLAMA_URL:-http://ollama:11434}"
  export PDF_EXTRACTOR_URL="${PDF_EXTRACTOR_URL:-http://pdf-extractor:8080}"
}
