#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${REPO_ROOT}/ops/anki/anki_collection_readonly_summary.py"
DOC="${REPO_ROOT}/docs/stage-17k-b-r3-table-name-readonly-anki-summary.md"

test -f "${SCRIPT}"
test -x "${SCRIPT}"
test -f "${DOC}"

grep -Fq "load_deck_names_from_table" "${SCRIPT}"
grep -Fq "load_note_type_names_from_table" "${SCRIPT}"
grep -Fq "load_fields_by_note_type" "${SCRIPT}"
grep -Fq "load_templates_by_note_type" "${SCRIPT}"
grep -Fq "decks_table" "${SCRIPT}"
grep -Fq "notetypes_table" "${SCRIPT}"
grep -Fq "schema_features" "${SCRIPT}"
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

echo "PASS: Stage 17K-B-R3 table-name read-only Anki summary smoke passed"
