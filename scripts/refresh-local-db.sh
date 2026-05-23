#!/usr/bin/env bash
# Pulls a fresh snapshot from Cloud SQL into your local beta_tracker database.
# Safe: read-only from production, no local writes go upstream.
# Run from the repo root: bash scripts/refresh-local-db.sh

set -euo pipefail

# Load local secrets if present (gitignored)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$SCRIPT_DIR/.env.local" ]]; then
  # shellcheck disable=SC1091
  set -a; source "$SCRIPT_DIR/.env.local"; set +a
fi

INSTANCE="beta-tracker-497019:us-central1:beta-tracker-db"
PROXY_PORT=5433
DB_NAME="beta_tracker"
DB_USER="app_user"
DUMP_FILE="/tmp/cloudsql-dump-$(date +%Y%m%d-%H%M%S).sql"

echo "→ Starting Cloud SQL Auth Proxy on port $PROXY_PORT..."
cloud-sql-proxy --port "$PROXY_PORT" "$INSTANCE" &
PROXY_PID=$!
trap "kill $PROXY_PID 2>/dev/null; echo '→ Proxy stopped.'" EXIT

echo "→ Waiting for proxy to be ready..."
for i in {1..20}; do
  if lsof -i:"$PROXY_PORT" -sTCP:LISTEN &>/dev/null; then break; fi
  sleep 1
done
lsof -i:"$PROXY_PORT" -sTCP:LISTEN &>/dev/null || { echo "Proxy failed to start"; exit 1; }

echo "→ Dumping $DB_NAME from Cloud SQL..."
PGPASSWORD="${CLOUDSQL_APP_PASSWORD:?Set CLOUDSQL_APP_PASSWORD env var}" \
  pg_dump \
    -h 127.0.0.1 -p "$PROXY_PORT" \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    --no-owner --no-acl \
    -f "$DUMP_FILE"

echo "→ Restoring into local $DB_NAME..."
psql -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
psql -d postgres -c "CREATE DATABASE $DB_NAME;"
psql -d "$DB_NAME" -f "$DUMP_FILE"

echo "→ Copying dump to backup.sql in repo root..."
cp "$DUMP_FILE" "$(dirname "$0")/../backup.sql"

echo "✓ Done. Local $DB_NAME is now a fresh copy of production."
echo "  Dump saved to: $DUMP_FILE"
