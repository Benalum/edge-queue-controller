#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3s-r2-ct203-read-only-dry-run-result.md"

echo "=== Stage 16 E3S-R3 smoke: documented read-only dry-run result ==="

test -s "$DOC"

grep -F "E3S_R2_CT203_READ_ONLY_DRY_RUN_OK" "$DOC"
grep -F "NO_DB_WRITE" "$DOC"
grep -F "DB_OPEN_MODE=sqlite_uri_mode_ro_immutable" "$DOC"
grep -F "DB_INTEGRITY=ok" "$DOC"
grep -F "QUEUED_INSPECTED=2" "$DOC"
grep -F "ELIGIBLE_WOULD_CLAIM_COUNT=0" "$DOC"
grep -F "WOULD_CLAIM none" "$DOC"
grep -F "43798528 1782062257 /var/lib/edge-queue-controller/edge_queue.sqlite3" "$DOC"
grep -F "job_id=23" "$DOC"
grep -F "job_id=24" "$DOC"
grep -F "model_not_allowlisted" "$DOC"
grep -F "Do not reuse job 27" "$DOC"

echo "E3S_R3_DOC_SMOKE_OK"
