#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13r-record-sanitized-download-proof.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13r-record-sanitized-download-proof"

test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "Record Sanitized Download Snapshot Proof" "$DOC"
grep -Fq "Browser proof passed" "$DOC"
grep -Fq "buddies-who-study-local-backup-v2-2026-07-05T23-33-14-803Z.json" "$DOC"
grep -Fq "2026-07-05T23:33:14.795Z" "$DOC"
grep -Fq "docs: 11" "$DOC"
grep -Fq "decks: 2" "$DOC"
grep -Fq "cards: 2" "$DOC"
grep -Fq "sessions: 16" "$DOC"
grep -Fq "backendProgress" "$DOC"
grep -Fq "backendReviewSummary" "$DOC"
grep -Fq "backendSessions" "$DOC"
grep -Fq "backendSyncedAt" "$DOC"
grep -Fq "No source mutation" "$DOC"
grep -Fq "No current-file save" "$DOC"
grep -Fq "No same-file write path" "$DOC"

echo "PASS stage-17k-r13r record sanitized download proof smoke"
