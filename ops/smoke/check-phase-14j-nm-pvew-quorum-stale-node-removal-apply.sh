#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-nm-pvew-quorum-stale-node-removal-apply.md"
PUBLIC_BASE="${PUBLIC_BASE:-https://alexhartel.com}"

echo "=== Phase 14J-NM smoke: quorum cleanup checkpoint ==="
echo "MUTATION_SCOPE=read_only_smoke"
echo "NO live infra mutation"
echo "NO pvecm expected mutation"
echo "NO pvecm delnode"
echo "NO corosync/pve config mutation"
echo "NO CT/VM start/stop/restart"
echo "NO storage mutation"
echo

test -f "$DOC"
grep -Fq "PVEW Quorum Stale-Node Removal Apply" "$DOC"
grep -Fq "config_version" "$DOC"
grep -Fq "Final corosync config contains only" "$DOC"
grep -Fq "reboot durability has not yet been proven" "$DOC"
grep -Fq "No VM/CT restart was performed" "$DOC"
echo "PASS: doc content present"

ssh -o BatchMode=yes -o ConnectTimeout=8 pvew 'bash -s' <<'REMOTE'
set -euo pipefail

pvecm status | grep -Eq '^Quorate:[[:space:]]+Yes$'
pvecm status | grep -Eq '^Expected votes:[[:space:]]+1$'
pvecm status | grep -Eq '^Total votes:[[:space:]]+1$'
grep -Eq '^[[:space:]]*name:[[:space:]]*pvew([[:space:]]|$)' /etc/pve/corosync.conf
if grep -Eq '^[[:space:]]*name:[[:space:]]*pveso([[:space:]]|$)' /etc/pve/corosync.conf; then exit 1; fi
if grep -Eq '^[[:space:]]*name:[[:space:]]*pve([[:space:]]|$)' /etc/pve/corosync.conf; then exit 1; fi
pct status 203 | grep -q running
pct status 204 | grep -q stopped
qm status 200 | grep -q running
findmnt -rn /srv/apc-private-data >/dev/null 2>&1 && exit 1 || true
[ -e /dev/mapper/apc_private_data ] && exit 1 || true
REMOTE
echo "PASS: live pvew quorum/guest/storage invariants"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
code="$(curl -fsS --max-time 15 -o "$tmp" -w '%{http_code}' "$PUBLIC_BASE/system/status")"
echo "public_status_http=$code"
test "$code" = "200"

python3 - "$tmp" <<'PY'
import json, sys
data=json.load(open(sys.argv[1]))
schema=(data.get("normalized") or {}).get("schema_version") or data.get("schema_version") or data.get("schema")
print("schema=" + str(schema))
if str(schema) != "2":
    raise SystemExit("schema not 2")
PY

echo "RESULT=PASS_PHASE_14J_NM_QUORUM_CLEANUP_CHECKPOINT_SMOKE"
