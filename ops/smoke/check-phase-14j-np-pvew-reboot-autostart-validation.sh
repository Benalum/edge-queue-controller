#!/usr/bin/env bash
set -euo pipefail
DOC="docs/phase-14j-np-pvew-reboot-autostart-validation.md"
PUBLIC_BASE="${PUBLIC_BASE:-https://alexhartel.com}"

echo "=== Phase 14J-NP smoke: post-reboot checkpoint ==="
test -f "$DOC"
grep -Fq "PVEW Reboot Autostart Validation" "$DOC"
grep -Fq "Boot ID changed" "$DOC"
grep -Fq "CT203 controller health recovered with schema version 2" "$DOC"
grep -Fq "validation-script path bug" "$DOC"

ssh -o BatchMode=yes -o ConnectTimeout=8 pvew 'bash -s' <<'REMOTE'
set -euo pipefail
pvecm status > /tmp/apc-np-smoke-pvecm.txt
grep -Eq '^Config Version:[[:space:]]+5$' /tmp/apc-np-smoke-pvecm.txt
grep -Eq '^Quorate:[[:space:]]+Yes$' /tmp/apc-np-smoke-pvecm.txt
grep -Eq '^Expected votes:[[:space:]]+1$' /tmp/apc-np-smoke-pvecm.txt
grep -Eq '^Total votes:[[:space:]]+1$' /tmp/apc-np-smoke-pvecm.txt
cp /etc/pve/corosync.conf /tmp/apc-np-smoke-corosync.conf
grep -Eq '^[[:space:]]*name:[[:space:]]*pvew([[:space:]]|$)' /tmp/apc-np-smoke-corosync.conf
if grep -Eq '^[[:space:]]*name:[[:space:]]*pveso([[:space:]]|$)' /tmp/apc-np-smoke-corosync.conf; then exit 1; fi
if grep -Eq '^[[:space:]]*name:[[:space:]]*pve([[:space:]]|$)' /tmp/apc-np-smoke-corosync.conf; then exit 1; fi
pct status 203 | grep -q running
pct status 204 | grep -q stopped
qm status 200 | grep -q running
findmnt -rn /srv/apc-private-data >/dev/null 2>&1 && exit 1 || true
[ -e /dev/mapper/apc_private_data ] && exit 1 || true
pct exec 203 -- curl -fsS --max-time 5 http://127.0.0.1:7070/system/status >/dev/null
REMOTE

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
code="$(curl -fsS --max-time 15 -o "$tmp" -w '%{http_code}' "$PUBLIC_BASE/system/status")"
echo "public_status_http=$code"
test "$code" = "200"
echo "RESULT=PASS_PHASE_14J_NP_POST_REBOOT_CHECKPOINT_SMOKE"
