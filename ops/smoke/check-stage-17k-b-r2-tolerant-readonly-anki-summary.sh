#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${REPO_ROOT}/ops/anki/anki_collection_readonly_summary.py"
DOC="${REPO_ROOT}/docs/stage-17k-b-r2-tolerant-readonly-anki-summary.md"

test -f "${SCRIPT}"
test -x "${SCRIPT}"
test -f "${DOC}"

grep -Fq "load_json_object_tolerant" "${SCRIPT}"
grep -Fq "parse_warnings" "${SCRIPT}"
grep -Fq "fallback_cards_did" "${SCRIPT}"
grep -Fq "fallback_notes_mid" "${SCRIPT}"
grep -Fq "mode=ro" "${SCRIPT}"
grep -Fq "writes_performed" "${SCRIPT}"
grep -Fq "uploads_performed" "${SCRIPT}"

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

echo "PASS: Stage 17K-B-R2 tolerant read-only Anki summary smoke passed"
