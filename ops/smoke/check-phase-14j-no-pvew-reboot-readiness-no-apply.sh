#!/usr/bin/env bash
set -euo pipefail
DOC="docs/phase-14j-no-pvew-reboot-readiness-no-apply.md"
PUBLIC_BASE="${PUBLIC_BASE:-https://alexhartel.com}"

echo "=== Phase 14J-NO smoke R3: reboot readiness no-apply ==="
test -f "$DOC"
grep -Fq "PVEW Reboot Readiness No-Apply" "$DOC"
grep -Fq "PVEW is ready for a separately approved reboot/autostart validation phase" "$DOC"
grep -Fq "APPROVE_PHASE_14J_NP_PVEW_REBOOT_AUTOSTART_VALIDATION_ALLOW_REBOOT_ONLY_NO_STORAGE_UNLOCK_NO_CT204_NO_WORKERS" "$DOC"

ssh -o BatchMode=yes -o ConnectTimeout=8 pvew 'bash -s' <<'REMOTE'
set -euo pipefail
pvecm status > /tmp/apc-no-smoke-status.txt
cp /etc/pve/corosync.conf /tmp/apc-no-smoke-corosync.conf
grep -Eq '^Config Version:[[:space:]]+5$' /tmp/apc-no-smoke-status.txt
grep -Eq '^Quorate:[[:space:]]+Yes$' /tmp/apc-no-smoke-status.txt
grep -Eq '^Expected votes:[[:space:]]+1$' /tmp/apc-no-smoke-status.txt
grep -Eq '^Total votes:[[:space:]]+1$' /tmp/apc-no-smoke-status.txt
grep -Eq '^[[:space:]]*name:[[:space:]]*pvew([[:space:]]|$)' /tmp/apc-no-smoke-corosync.conf
if grep -Eq '^[[:space:]]*name:[[:space:]]*pveso([[:space:]]|$)' /tmp/apc-no-smoke-corosync.conf; then exit 1; fi
if grep -Eq '^[[:space:]]*name:[[:space:]]*pve([[:space:]]|$)' /tmp/apc-no-smoke-corosync.conf; then exit 1; fi
pct status 203 | grep -q running
pct status 204 | grep -q stopped
qm status 200 | grep -q running
pct config 203 | grep -q '^onboot: 1$'
pct config 204 | grep -q '^onboot: 0$'
qm config 200 | grep -q '^onboot: 1$'
findmnt -rn /srv/apc-private-data >/dev/null 2>&1 && exit 1 || true
[ -e /dev/mapper/apc_private_data ] && exit 1 || true
REMOTE

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
code="$(curl -fsS --max-time 15 -o "$tmp" -w '%{http_code}' "$PUBLIC_BASE/system/status")"
echo "public_status_http=$code"
test "$code" = "200"
echo "RESULT=PASS_PHASE_14J_NO_R3_REBOOT_READINESS_SMOKE"
