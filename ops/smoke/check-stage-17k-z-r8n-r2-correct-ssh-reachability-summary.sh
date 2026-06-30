#!/usr/bin/env bash
set -euo pipefail

RAW_OUT="docs/generated/stage-17k-z-r8n-readonly-ssh-reachability-diagnostic.txt"
JSON_OUT="docs/generated/stage-17k-z-r8n-readonly-ssh-reachability-diagnostic.json"
DOC="docs/stage-17k-z-r8n-r2-correct-ssh-reachability-summary.md"

echo "=== Stage 17K-Z-R8N-R2 correction smoke ==="

test -f "$RAW_OUT"
test -f "$JSON_OUT"
test -f "$DOC"

grep -Fq "ssh: connect to host 100.127.73.75 port 22: Connection timed out" "$RAW_OUT"
grep -Fq "ssh: connect to host 100.105.133.69 port 22: Connection timed out" "$RAW_OUT"
grep -Fq "100.127.73.75" "$RAW_OUT"
grep -Fq "100.105.133.69" "$RAW_OUT"
grep -Fq "HTTP/2 200" "$RAW_OUT"
grep -Fq "HTTP/2 301" "$RAW_OUT"

grep -Fq '"stage": "17K-Z-R8N-R2"' "$JSON_OUT"
grep -Fq '"pvew_ssh_hostname_ok": false' "$JSON_OUT"
grep -Fq '"vm200_ssh_hostname_ok": false' "$JSON_OUT"
grep -Fq '"pvew_ssh_timeout_or_failed": true' "$JSON_OUT"
grep -Fq '"vm200_ssh_timeout_or_failed": true' "$JSON_OUT"
grep -Fq '"public_routes_healthy_but_local_ssh_to_pvew_and_vm200_unreachable"' "$JSON_OUT"

grep -Fq "Stage 17K-Z-R8N-R2" "$DOC"
grep -Fq "SSH to PVEW Tailscale IP timed out" "$DOC"
grep -Fq "Do not patch live CT203 email sender configuration" "$DOC"

python3 -m json.tool "$JSON_OUT" >/dev/null

echo "PASS Stage 17K-Z-R8N-R2 correction smoke"
