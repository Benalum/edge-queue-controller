#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${REPO_ROOT}/ops/anki/anki_collection_readonly_summary.py"
DOC="${REPO_ROOT}/docs/stage-17k-b-readonly-anki-summary-tool.md"

test -f "${SCRIPT}"
test -x "${SCRIPT}"
test -f "${DOC}"

grep -Fq "mode=ro" "${SCRIPT}"
grep -Fq "sqlite_open_mode" "${SCRIPT}"
grep -Fq "writes_performed" "${SCRIPT}"
grep -Fq "uploads_performed" "${SCRIPT}"
grep -Fq "SELECT COUNT(*) FROM cards" "${SCRIPT}"
grep -Fq "SELECT COUNT(*) FROM notes" "${SCRIPT}"
grep -Fq "Stage 17K-B — Read-only Anki Collection Summary Tool" "${DOC}"

for forbidden in \
  "INSERT INTO" \
  "UPDATE " \
  "DELETE FROM" \
  "DROP TABLE" \
  "CREATE TABLE" \
  "ALTER TABLE"; do
  if grep -Fq "${forbidden}" "${SCRIPT}"; then
    echo "FAIL: write-capable SQL found: ${forbidden}" >&2
    exit 1
  fi
done

python3 "${SCRIPT}" --help >/dev/null

echo "PASS: Stage 17K-B read-only Anki summary tool smoke passed"
