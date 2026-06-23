.PHONY: up down logs build dbt-run dbt-test dbt-debug docs clean labor-1-build labor-1-run labor-1-shell

# ─── Infrastructure ─────────────────────────────────────────────────────────

up:
	docker compose up -d postgres pgadmin
	@echo ""
	@echo "Services démarrés :"
	@echo "  → PostgreSQL  : localhost:5432"
	@echo "  → pgAdmin     : http://localhost:8080"
	@echo "  → Email pgAdmin    : admin@dbt.com"
	@echo "  → Password pgAdmin : admin_password"

down:
	docker compose --profile dbt --profile docs down

logs:
	docker compose logs -f postgres pgadmin

build:
	docker compose build dbt

# ─── dbt ────────────────────────────────────────────────────────────────────

dbt-run:
	docker compose run --rm dbt run

dbt-test:
	docker compose run --rm dbt test

dbt-debug:
	docker compose run --rm dbt debug

dbt-deps:
	docker compose run --rm dbt deps

dbt-compile:
	docker compose run --rm dbt compile

dbt-seed:
	docker compose run --rm dbt seed

dbt-freshness:
	docker compose run --rm dbt source freshness

# ─── Documentation ──────────────────────────────────────────────────────────

docs:
	docker compose run --rm dbt docs generate
	@echo ""
	@echo "Démarrage du serveur de documentation..."
	docker compose --profile docs up -d dbt-docs
	@echo "  → Documentation : http://localhost:8081"

docs-stop:
	docker compose --profile docs down dbt-docs

# ─── Utilitaires ────────────────────────────────────────────────────────────

clean:
	docker compose --profile dbt --profile docs down -v
	@echo "Volumes supprimés."

ps:
	docker compose ps

# ─── Labor 1 Python ─────────────────────────────────────────────────────────

labor-1-build:
	docker compose --profile labor build labor-1

labor-1-run:
	docker compose --profile labor run --rm labor-1

labor-1-shell:
	docker compose --profile labor run --rm --entrypoint /bin/sh labor-1
