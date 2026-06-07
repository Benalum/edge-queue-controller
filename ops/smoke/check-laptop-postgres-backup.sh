#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== laptop Postgres backup smoke ==="

ENV_FILE="${AI_PLATFORM_CONTROLLER_DB_ENV:-$HOME/.config/ai-platform-controller/postgres.env}"

if [ ! -f "$ENV_FILE" ]; then
  echo "FAIL: missing DB env file: $ENV_FILE"
  exit 1
fi

if [ "$(stat -c '%a' "$ENV_FILE")" != "600" ]; then
  echo "FAIL: DB env file must be chmod 600: $ENV_FILE"
  exit 1
fi

TMP_BACKUP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_BACKUP_DIR"' EXIT

OUTPUT="$(
  AI_PLATFORM_CONTROLLER_BACKUP_DIR="$TMP_BACKUP_DIR" \
  AI_PLATFORM_CONTROLLER_BACKUP_RETENTION_DAYS=1 \
  bash ops/db/backup-laptop-postgres.sh
)"

echo "$OUTPUT"

BACKUP_FILE="$(printf '%s\n' "$OUTPUT" | awk -F= '/^BACKUP_FILE=/{print $2}' | tail -1)"
MANIFEST_FILE="$(printf '%s\n' "$OUTPUT" | awk -F= '/^MANIFEST_FILE=/{print $2}' | tail -1)"

if [ -z "$BACKUP_FILE" ]; then
  echo "FAIL: backup script did not print BACKUP_FILE"
  exit 1
fi

if [ ! -s "$BACKUP_FILE" ]; then
  echo "FAIL: backup file missing or empty: $BACKUP_FILE"
  exit 1
fi

if [ -z "$MANIFEST_FILE" ] || [ ! -s "$MANIFEST_FILE" ]; then
  echo "FAIL: manifest file missing or empty: $MANIFEST_FILE"
  exit 1
fi

pg_restore -l "$BACKUP_FILE" >/dev/null

if [ ! -L "$TMP_BACKUP_DIR/latest.dump" ]; then
  echo "FAIL: latest.dump symlink was not created"
  exit 1
fi

grep -F "AI Platform Controller Postgres Backup" "$MANIFEST_FILE" >/dev/null

echo "PASS: laptop Postgres backup smoke passed"
