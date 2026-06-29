#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="$ROOT/frontend/wrapper-ui/apc-wrapper-local/index.html"
SELECTOR="$ROOT/frontend/wrapper-ui/apc-wrapper-local/privatepages/study-source-selector.js"
ANKI="$ROOT/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-readonly-session.js"
DOC="$ROOT/docs/stage-17k-w-remove-anki-from-study-page.md"

test -f "$INDEX"
test -f "$SELECTOR"
test -f "$ANKI"
test -f "$DOC"

grep -Fq "stage17kw-study-page-mydecks-only-20260628" "$INDEX"
grep -Fq "stage17kw-anki-session-companion-only-20260628" "$INDEX"
grep -Fq "stage17kw-study-page-mydecks-only-20260628" "$SELECTOR"
grep -Fq "stage17kw-anki-session-companion-only-20260628" "$ANKI"

grep -Fq "Study with MyDecks" "$SELECTOR"
grep -Fq "study_page_native_only: true" "$SELECTOR"
grep -Fq "external_file_ui_on_study_allowed: false" "$SELECTOR"
grep -Fq "if (!isStudyRoute()) return;" "$SELECTOR"

for forbidden in \
  "Study with Anki" \
  "Selected Anki deck" \
  "Anki stays browser-local" \
  "browser-local/read-only" \
  "select-anki-deck" \
  "Use Anki Deck" \
  "Load Anki in Profile first" \
  "readAnkiSummary" \
  "ankiDeckRows"
do
  if grep -Fq "$forbidden" "$SELECTOR"; then
    echo "forbidden Study selector marker remains: $forbidden"
    exit 1
  fi
done

grep -Fq "if (!isCompanionRoute()) return;" "$ANKI"
grep -Fq 'document.querySelector("#apc-companion-local-anki-bridge")' "$ANKI"

for forbidden in \
  "function isStudyRoute()" \
  "if (!isStudyRoute()" \
  'document.querySelector("#apc-study-source-selector")' \
  'document.querySelector("[data-page='\''study'\'']")'
do
  if grep -Fq "$forbidden" "$ANKI"; then
    echo "forbidden Anki session Study marker remains: $forbidden"
    exit 1
  fi
done

grep -Fq "Remove Anki from Study Page" "$DOC"
grep -Fq "not a CSS hide" "$DOC"
grep -Fq "MyDecks-only" "$DOC"
grep -Fq "panel mounts only on Companion, not Study" "$DOC"
grep -Fq "No backend deploy, DB write, Anki write" "$DOC"

if command -v node >/dev/null 2>&1; then
  node --check "$SELECTOR"
  node --check "$ANKI"
fi

echo "PASS: Stage 17K-W remove Anki from Study page smoke passed"
