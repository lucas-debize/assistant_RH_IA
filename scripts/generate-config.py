#!/usr/bin/env python3

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parents[1]
GENERATED_DIR = PROJECT_DIR / "n8n" / "generated"
TEMPLATES_DIR = PROJECT_DIR / "n8n" / "templates"

REQUIRED_VARS = [
    "POSTGRES_USER",
    "POSTGRES_PASSWORD",
    "POSTGRES_DB",
    "N8N_ENCRYPTION_KEY",
    "IMAP_HOST",
    "IMAP_USER",
    "IMAP_PASSWORD",
    "SMTP_HOST",
    "SMTP_USER",
    "SMTP_PASSWORD",
    "RECRUITER_EMAIL",
]

DEFAULTS = {
    "IMAP_PORT": "993",
    "IMAP_MAILBOX": "INBOX",
    "SMTP_PORT": "587",
    "OLLAMA_MODEL": "mistral",
    "OLLAMA_URL": "http://ollama:11434",
    "PDF_EXTRACTOR_URL": "http://pdf-extractor:8080",
    "RH_DB_HOST": "postgres",
    "RH_DB_PORT": "5432",
    "N8N_PORT": "5678",
    "N8N_HOST": "localhost",
}


def load_env(env_path: Path) -> dict[str, str]:
    env: dict[str, str] = {}
    if not env_path.exists():
        print(f"❌ Fichier {env_path} introuvable", file=sys.stderr)
        sys.exit(1)

    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip().rstrip("\r")
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        key, _, value = line.partition("=")
        env[key.strip()] = value.strip().strip('"').strip("'")

    for key, value in DEFAULTS.items():
        env.setdefault(key, value)

    for pwd_key in ("IMAP_PASSWORD", "SMTP_PASSWORD"):
        if pwd_key in env:
            env[pwd_key] = env[pwd_key].replace(" ", "")

    missing = [v for v in REQUIRED_VARS if not env.get(v)]
    if missing:
        print(f"❌ Variables manquantes dans .env : {', '.join(missing)}", file=sys.stderr)
        sys.exit(1)

    return env


def substitute_placeholders(content: str, env: dict[str, str]) -> str:
    def replacer(match: re.Match[str]) -> str:
        key = match.group(1)
        if key not in env:
            print(f"❌ Placeholder @{key}@ sans valeur dans .env", file=sys.stderr)
            sys.exit(1)
        return env[key]

    result = re.sub(r"@@([A-Z0-9_]+)@@", replacer, content)
    leftover = re.findall(r"@@([A-Z0-9_]+)@@", result)
    if leftover:
        print(f"❌ Placeholders non résolus : {', '.join(set(leftover))}", file=sys.stderr)
        sys.exit(1)
    return result


def generate_credentials(env: dict[str, str]) -> None:
    template = (TEMPLATES_DIR / "credentials.json.template").read_text(encoding="utf-8")
    output = substitute_placeholders(template, env)
    json.loads(output)
    (GENERATED_DIR / "credentials.json").write_text(output + "\n", encoding="utf-8")


def generate_workflow(env: dict[str, str]) -> None:
    template = (TEMPLATES_DIR / "assistant-rh-ia.template.json").read_text(encoding="utf-8")
    output = substitute_placeholders(template, env)
    json.loads(output)
    (GENERATED_DIR / "workflow.json").write_text(output + "\n", encoding="utf-8")


def main() -> None:
    env_path = PROJECT_DIR / ".env"
    env = load_env(env_path)
    GENERATED_DIR.mkdir(parents=True, exist_ok=True)

    generate_credentials(env)
    generate_workflow(env)

    print("✅ Généré : n8n/generated/credentials.json")
    print("✅ Généré : n8n/generated/workflow.json")
    print(f"   IMAP  → {env['IMAP_USER']} @ {env['IMAP_HOST']} (mailbox: {env['IMAP_MAILBOX']})")
    print(f"   SMTP  → {env['SMTP_USER']} @ {env['SMTP_HOST']}")
    print(f"   Dest  → {env['RECRUITER_EMAIL']}")
    print(f"   IA    → {env['OLLAMA_MODEL']} @ {env['OLLAMA_URL']}")


if __name__ == "__main__":
    main()
