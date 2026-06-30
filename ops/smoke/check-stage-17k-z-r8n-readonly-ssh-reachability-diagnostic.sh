#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8n-readonly-ssh-reachability-diagnostic.md"
RAW_OUT="docs/generated/stage-17k-z-r8n-readonly-ssh-reachability-diagnostic.txt"
JSON_OUT="docs/generated/stage-17k-z-r8n-readonly-ssh-reachability-diagnostic.json"

echo "=== Stage 17K-Z-R8N SSH diagnostic smoke ==="

test -f "$DOC"
test -f "$RAW_OUT"
test -f "$JSON_OUT"

grep -Fq "Stage 17K-Z-R8N" "$DOC"
grep -Fq "PVEW SSH timed out" "$DOC"
grep -Fq "does not mutate network config" "$DOC"

grep -Fq "pvew_host=pvew" "$RAW_OUT"
grep -Fq "vm200_host=website-edge" "$RAW_OUT"
grep -Fq "## TCP reachability checks" "$RAW_OUT"
grep -Fq "## public route still healthy" "$RAW_OUT"

grep -Fq '"stage": "17K-Z-R8N"' "$JSON_OUT"
grep -Fq '"read_only": true' "$JSON_OUT"
grep -Fq '"recommended_next_stage":' "$JSON_OUT"

python3 -m json.tool "$JSON_OUT" >/dev/null

echo "PASS Stage 17K-Z-R8N SSH diagnostic smoke"
