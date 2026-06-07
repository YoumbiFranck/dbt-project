# dbt Core — Lokale Lernumgebung mit Docker

Eine vollständige, containerisierte Entwicklungsumgebung zum Erlernen von **dbt Core** mit PostgreSQL als Data Warehouse.

---

## Inhaltsverzeichnis

- [Übersicht](#übersicht)
- [Voraussetzungen](#voraussetzungen)
- [Projektstruktur](#projektstruktur)
- [Schnellstart](#schnellstart)
- [Dienste](#dienste)
- [Datenpipeline](#datenpipeline)
- [dbt-Befehle](#dbt-befehle)
- [Datenbankzugang](#datenbankzugang)
- [Tests](#tests)
- [Dokumentation](#dokumentation)
- [Umgebungsvariablen](#umgebungsvariablen)
- [Nützliche Befehle](#nützliche-befehle)

---

## Übersicht

Dieses Projekt simuliert eine realistische Datentransformationspipeline:

```
raw (PostgreSQL-Quelltabellen)
        ↓
staging (dbt Views — Bereinigung & Typisierung)
        ↓
marts (dbt Tabellen — analysebereite Daten)
```

Die gesamte Infrastruktur läuft in Docker-Containern. Es muss **nichts direkt auf dem Mac installiert** werden (außer Docker).

---

## Voraussetzungen

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) für Mac (Version 4.x oder neuer)
- `make` (auf macOS standardmäßig vorhanden via Xcode Command Line Tools)

Docker und `make` prüfen:

```bash
docker --version
make --version
```

---

## Projektstruktur

```
dbt-project/
├── .env                          # Umgebungsvariablen (Passwörter, Ports)
├── docker-compose.yml            # Orchestrierung aller Dienste
├── Dockerfile.dbt                # Benutzerdefiniertes dbt-Image
├── Makefile                      # Hilfsbefehle
│
├── init/
│   └── 01_init.sql               # Rohdaten-Schema + Demodaten
│
└── dbt/
    ├── dbt_project.yml           # dbt-Projektkonfiguration
    ├── profiles.yml              # PostgreSQL-Verbindung
    ├── packages.yml              # dbt-Pakete (dbt_utils)
    └── models/
        ├── staging/
        │   ├── _sources.yml      # Quelldefinitionen
        │   ├── _staging.yml      # Tests & Dokumentation
        │   ├── stg_customers.sql
        │   ├── stg_orders.sql
        │   └── stg_products.sql
        └── marts/
            ├── _marts.yml        # Tests & Dokumentation
            ├── dim_customers.sql
            ├── dim_products.sql
            └── fct_orders.sql
```

---

## Schnellstart

```bash
# 1. Ins Projektverzeichnis wechseln
cd ~/Desktop/dbt-project

# 2. PostgreSQL und pgAdmin starten
make up

# 3. dbt-Image bauen (nur beim ersten Mal)
make build

# 4. dbt-Pakete installieren (dbt_utils)
make dbt-deps

# 5. Verbindung zu PostgreSQL prüfen
make dbt-debug

# 6. Alle dbt-Modelle ausführen
make dbt-run

# 7. Tests ausführen
make dbt-test

# 8. Dokumentation generieren und öffnen
make docs
```

---

## Dienste

| Dienst | Image | Beschreibung | URL / Port |
|--------|-------|--------------|------------|
| `postgres` | `postgres:16-alpine` | Data Warehouse | `localhost:5432` |
| `pgadmin` | `dpage/pgadmin4:latest` | Web-UI für PostgreSQL | [http://localhost:8080](http://localhost:8080) |
| `dbt` | Custom (Python 3.11) | dbt-Ausführung (ephemer) | — |
| `dbt-docs` | Custom (Python 3.11) | dbt-Dokumentationsserver | [http://localhost:8081](http://localhost:8081) |

> **Hinweis:** Der `dbt`-Container ist **ephemer** — er startet bei Bedarf und beendet sich nach dem Ausführen des Befehls. Das entspricht dem normalen dbt-Verhalten in CI/CD-Pipelines.

---

## Datenpipeline

### Rohdaten (`raw`-Schema)

Beim Start von PostgreSQL wird das Skript `init/01_init.sql` automatisch ausgeführt. Es erstellt drei Quelltabellen mit Demodaten:

| Tabelle | Zeilen | Beschreibung |
|---------|--------|--------------|
| `raw.customers` | 12 | Kundendaten (mit absichtlich fehlenden Werten) |
| `raw.products` | 10 | Produktkatalog |
| `raw.orders` | 20 | Bestellungen mit verschiedenen Statuswerten |

> Die Rohdaten enthalten bewusst "unsaubere" Daten: VARCHAR statt DATE, fehlende E-Mails, NULL-Länder — genau so, wie es in der Praxis vorkommt.

### Staging-Schicht (`staging`-Schema)

dbt erstellt **Views** zur Bereinigung und Typisierung der Rohdaten:

| Modell | Quelle | Transformationen |
|--------|--------|-----------------|
| `stg_customers` | `raw.customers` | Typ-Cast, E-Mail-Normalisierung |
| `stg_orders` | `raw.orders` | Typ-Cast, Berechnung von `order_total` |
| `stg_products` | `raw.products` | Typ-Cast, VARCHAR → NUMERIC, VARCHAR → BOOLEAN |

### Marts-Schicht (`marts`-Schema)

dbt erstellt **Tabellen** für die Analyse, mit `ref()` zwischen den Modellen:

| Modell | Quellen | Beschreibung |
|--------|---------|--------------|
| `dim_customers` | `stg_customers` + `stg_orders` | Kundendimension mit aggregierten Bestellkennzahlen |
| `dim_products` | `stg_products` + `stg_orders` | Produktdimension (nur aktive Produkte) mit Verkaufsmetriken |
| `fct_orders` | `stg_orders` + `stg_customers` + `stg_products` | Bestellfaktentabelle mit denormalisierten Attributen |

### Abhängigkeitsgraph (DAG)

```
raw.customers ──► stg_customers ──► dim_customers
                       │                  ▲
                       └──────────────────┤
                                          │
raw.orders ────► stg_orders ──────► fct_orders
                       │                  │
                       └──────────────────┤
                                          ▼
raw.products ──► stg_products ──► dim_products
```

---

## dbt-Befehle

```bash
# Alle Modelle ausführen
make dbt-run

# Nur Staging-Modelle ausführen
docker compose run --rm dbt run --select staging

# Nur ein bestimmtes Modell ausführen
docker compose run --rm dbt run --select fct_orders

# Modell + alle Abhängigkeiten ausführen
docker compose run --rm dbt run --select +fct_orders

# Tests ausführen
make dbt-test

# Nur Tests für ein Modell ausführen
docker compose run --rm dbt test --select stg_customers

# Quellen auf Aktualität prüfen
make dbt-freshness

# Kompilierte SQL anzeigen (ohne Ausführung)
make dbt-compile

# Verbindung debuggen
make dbt-debug
```

---

## Datenbankzugang

### pgAdmin (Web-UI)

| Parameter | Wert |
|-----------|------|
| URL | [http://localhost:8080](http://localhost:8080) |
| E-Mail | `admin@dbt.com` |
| Passwort | `admin_password` |

**PostgreSQL-Server in pgAdmin hinzufügen:**

1. Rechtsklick auf „Servers" → „Register" → „Server..."
2. **Name:** `dbt-local`
3. Reiter **Connection:**
   - Host: `postgres`
   - Port: `5432`
   - Datenbank: `dbt_db`
   - Benutzername: `dbt_user`
   - Passwort: `dbt_password`

### Direktverbindung (psql)

```bash
docker exec -it dbt-postgres psql -U dbt_user -d dbt_db
```

Nützliche psql-Befehle:

```sql
-- Alle Schemas anzeigen
\dn

-- Tabellen im raw-Schema anzeigen
\dt raw.*

-- Inhalt einer Tabelle anzeigen
SELECT * FROM raw.customers LIMIT 5;
SELECT * FROM staging.stg_orders LIMIT 5;
SELECT * FROM marts.fct_orders LIMIT 5;
```

---

## Tests

dbt enthält vier Arten von generischen Tests, die in den `.yml`-Dateien definiert sind:

| Test | Beschreibung | Angewendet auf |
|------|--------------|----------------|
| `unique` | Keine doppelten Werte | Primärschlüssel |
| `not_null` | Kein NULL-Wert | Pflichtfelder |
| `accepted_values` | Nur erlaubte Werte | `status`-Spalten |
| `relationships` | Referenzielle Integrität | Fremdschlüssel |

```bash
# Alle Tests ausführen
make dbt-test

# Ergebnis: PASS / FAIL pro Test
```

---

## Dokumentation

```bash
# Dokumentation generieren und Server starten
make docs

# Browser öffnen
open http://localhost:8081

# Dokumentationsserver stoppen
make docs-stop
```

Die dbt-Dokumentation enthält:
- Interaktiven **DAG** (Abhängigkeitsgraph aller Modelle)
- Beschreibungen aller Modelle, Spalten und Tests
- Testergebnisse
- Kompilierte SQL-Abfragen

---

## Umgebungsvariablen

Alle Konfigurationswerte befinden sich in der `.env`-Datei:

```env
# PostgreSQL
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=dbt_db
POSTGRES_USER=dbt_user
POSTGRES_PASSWORD=dbt_password

# pgAdmin
PGADMIN_DEFAULT_EMAIL=admin@dbt.com
PGADMIN_DEFAULT_PASSWORD=admin_password
```

> **Sicherheitshinweis:** Die `.env`-Datei enthält Passwörter. Sie sollte **niemals** in ein öffentliches Git-Repository eingecheckt werden. Für produktive Umgebungen empfiehlt sich ein Secret-Management-System.

---

## Nützliche Befehle

```bash
make up           # PostgreSQL + pgAdmin starten
make down         # Alle Dienste stoppen
make logs         # Logs von PostgreSQL + pgAdmin anzeigen
make build        # dbt-Image neu bauen
make ps           # Status aller Container anzeigen

make dbt-run      # Alle dbt-Modelle ausführen
make dbt-test     # Alle dbt-Tests ausführen
make dbt-debug    # Verbindung zu PostgreSQL prüfen
make dbt-deps     # dbt-Pakete installieren
make dbt-compile  # SQL kompilieren (ohne Ausführung)

make docs         # Dokumentation generieren + Server starten
make docs-stop    # Dokumentationsserver stoppen

make clean        # Alle Container + Volumes löschen (Datenverlust!)
```

---

## Fehlerbehebung

**PostgreSQL startet nicht:**
```bash
# Logs prüfen
docker compose logs postgres

# Port bereits belegt?
lsof -i :5432
```

**dbt kann keine Verbindung herstellen:**
```bash
# Verbindung debuggen
make dbt-debug

# PostgreSQL läuft?
make ps
```

**Änderungen an Modellen werden nicht übernommen:**
```bash
# Modell neu bauen (erzwingt vollständige Ausführung)
docker compose run --rm dbt run --full-refresh
```

**Alle Daten zurücksetzen:**
```bash
# Volumes löschen und neu starten
make clean
make up
```
