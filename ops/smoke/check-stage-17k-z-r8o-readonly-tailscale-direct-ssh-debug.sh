#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8o-readonly-tailscale-direct-ssh-debug.md"
RAW_OUT="docs/generated/stage-17k-z-r8o-readonly-tailscale-direct-ssh-debug.txt"
JSON_OUT="docs/generated/stage-17k-z-r8o-readonly-tailscale-direct-ssh-debug.json"

echo "=== Stage 17K-Z-R8O Tailscale/direct SSH debug smoke ==="

test -f "$DOC"
test -f "$RAW_OUT"
test -f "$JSON_OUT"

grep -Fq "Stage 17K-Z-R8O" "$DOC"
grep -Fq "Tailscale/Direct SSH Debug" "$DOC"
grep -Fq "does not mutate network config" "$DOC"

grep -Fq "pvew_tailscale_ip=100.127.73.75" "$RAW_OUT"
grep -Fq "vm200_tailscale_ip=100.105.133.69" "$RAW_OUT"
grep -Fq "tailscale ping pvew ip" "$RAW_OUT"
grep -Fq "tailscale ping vm200 ip" "$RAW_OUT"
grep -Fq "direct TCP port checks" "$RAW_OUT"
grep -Fq "direct ssh concise checks" "$RAW_OUT"
grep -Fq "public route still healthy" "$RAW_OUT"

grep -Fq '"stage": "17K-Z-R8O"' "$JSON_OUT"
grep -Fq '"read_only": true' "$JSON_OUT"
grep -Fq '"pvew_tailscale_ip": "100.127.73.75"' "$JSON_OUT"
grep -Fq '"vm200_tailscale_ip": "100.105.133.69"' "$JSON_OUT"
grep -Fq '"recommended_next_stage":' "$JSON_OUT"

python3 -m json.tool "$JSON_OUT" >/dev/null

echo "PASS Stage 17K-Z-R8O Tailscale/direct SSH debug smoke"
