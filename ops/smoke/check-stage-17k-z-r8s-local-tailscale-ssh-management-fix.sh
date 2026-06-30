#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8s-local-tailscale-ssh-management-fix.md"
RAW_OUT="docs/generated/stage-17k-z-r8s-local-tailscale-ssh-management-fix.txt"
JSON_OUT="docs/generated/stage-17k-z-r8s-local-tailscale-ssh-management-fix.json"

echo "=== Stage 17K-Z-R8S local Tailscale SSH management fix smoke ==="

test -f "$DOC"
test -f "$RAW_OUT"
test -f "$JSON_OUT"

grep -Fq "Stage 17K-Z-R8S" "$DOC"
grep -Fq "apc-tailscale-management.conf" "$DOC"
grep -Fq "100.127.73.75" "$DOC"
grep -Fq "100.105.133.69" "$DOC"

grep -Fq "APC Tailscale management SSH aliases" "$RAW_OUT"
grep -Fq "Host pvew pvew-ts" "$RAW_OUT"
grep -Fq "Host website-edge vm200 website-edge-ts vm200-ts" "$RAW_OUT"
grep -Fq "hostname 100.127.73.75" "$RAW_OUT"
grep -Fq "hostname 100.105.133.69" "$RAW_OUT"
grep -Fq "bind_mode=" "$RAW_OUT"

grep -Fq '"stage": "17K-Z-R8S"' "$JSON_OUT"
grep -Fq '"local_laptop_ssh_config_mutation": true' "$JSON_OUT"
grep -Fq '"remote_mutation": false' "$JSON_OUT"
grep -Fq '"apc_tailscale_config_written": true' "$JSON_OUT"

python3 -m json.tool "$JSON_OUT" >/dev/null

echo "PASS Stage 17K-Z-R8S local Tailscale SSH management fix smoke"
