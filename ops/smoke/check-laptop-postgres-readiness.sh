#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== laptop Postgres readiness plan static check ==="

require_file() {
  if [ ! -f "$1" ]; then
    echo "FAIL: missing file $1"
    exit 1
  fi
  echo "OK: file $1"
}

require_fixed() {
  local file="$1"
  local text="$2"
  local label="$3"

  if grep -F -n "$text" "$file" >/dev/null 2>&1; then
    echo "OK: $label"
  else
    echo "FAIL: missing $label"
    echo "  file: $file"
    echo "  text: $text"
    exit 1
  fi
}

require_file docs/laptop-postgres-readiness.md
require_file docs/laptop-owned-data-plan.md
require_file docs/ct101-to-laptop-migration-map.md

require_fixed docs/laptop-postgres-readiness.md "postgresql.service was not found" "Postgres service absent finding"
require_fixed docs/laptop-postgres-readiness.md "psql was not installed" "psql absent finding"
require_fixed docs/laptop-postgres-readiness.md "postgres system user did not exist" "postgres user absent finding"
require_fixed docs/laptop-postgres-readiness.md "edge_queue.sqlite3" "current SQLite controller DB"
require_fixed docs/laptop-postgres-readiness.md "database name: ai_platform_controller" "target database name"
require_fixed docs/laptop-postgres-readiness.md "database user: ai_platform_controller" "target database user"
require_fixed docs/laptop-postgres-readiness.md "CT101 Postgres should not be the final source of truth" "CT101 Postgres not final owner"
require_fixed docs/laptop-postgres-readiness.md "Add backup script." "backup before migration"
require_fixed docs/laptop-postgres-readiness.md "Do not:" "no implementation constraints"
require_fixed docs/laptop-postgres-readiness.md "install Postgres" "no install yet"

echo "PASS: laptop Postgres readiness plan markers are present"
