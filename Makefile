.PHONY: setup start sync up down logs

setup start:
	@chmod +x scripts/*.sh scripts/lib/*.sh 2>/dev/null || true
	@./scripts/setup.sh

sync:
	@chmod +x scripts/*.sh scripts/lib/*.sh 2>/dev/null || true
	@./scripts/sync-n8n.sh

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f n8n
