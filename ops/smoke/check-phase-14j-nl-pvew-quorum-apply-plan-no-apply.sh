#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-nl-pvew-quorum-apply-plan-no-apply.md"
PUBLIC_BASE="${PUBLIC_BASE:-https://alexhartel.com}"

echo "=== Phase 14J-NL smoke: quorum apply plan no-apply ==="
echo "MUTATION_SCOPE=read_only_smoke"
echo "NO live infra mutation"
echo "NO pvecm expected mutation"
echo "NO pvecm delnode"
echo "NO corosync/pve cluster config mutation"
echo "NO CT/VM start/stop/restart"
echo "NO storage mutation"
echo "NO worker/model/scheduler/DB mutation"
echo

test -f "$DOC"
grep -Fq "PVEW Quorum Apply Plan No-Apply" "$DOC"
grep -Fq "Preferred durable path" "$DOC"
grep -Fq "Candidate apply class" "$DOC"
grep -Fq "Commands that are not approved" "$DOC"
grep -Fq "APPROVE_PHASE_14J_NM_PVEW_QUORUM_STALE_NODE_REMOVAL_APPLY_NO_REBOOT_NO_GUEST_RESTART" "$DOC"
grep -Fq "CT204 must be stopped and onboot=0" "$DOC"
grep -Fq "Private storage must be not mounted" "$DOC"
grep -Fq "Reboot validation should be a separate later approval" "$DOC"
echo "PASS: doc content present"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
code="$(curl -fsS --max-time 15 -o "$tmp" -w '%{http_code}' "$PUBLIC_BASE/system/status")"
echo "public_status_http=$code"
test "$code" = "200"

python3 - "$tmp" <<'PY'
import json, sys
data=json.load(open(sys.argv[1]))
schema=(data.get("normalized") or {}).get("schema_version") or data.get("schema_version") or data.get("schema")
text=json.dumps(data, sort_keys=True)
print("schema=" + str(schema))
if str(schema) != "2":
    raise SystemExit("schema not 2")
for needle in ["ct-203", "vm-200", "pvew", "ct-204", "manual-unlock-only"]:
    if needle not in text:
        raise SystemExit(f"missing {needle}")
print("PASS: public status expected nodes/policy")
PY

echo "RESULT=PASS_PHASE_14J_NL_QUORUM_APPLY_PLAN_SMOKE"
