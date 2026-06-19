#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-ni-pvew-quorum-architecture-decision-gate-no-apply.md"
PUBLIC_BASE="${PUBLIC_BASE:-https://alexhartel.com}"

echo "=== Phase 14J-NI smoke: PVEW quorum architecture decision gate no-apply ==="
echo "MUTATION_SCOPE=read_only_smoke"
echo "NO live infra mutation"
echo "NO pvecm expected mutation"
echo "NO corosync/pve cluster config mutation"
echo "NO CT/VM start/stop/restart"
echo "NO nginx reload/restart"
echo "NO Cloudflare/DNS/tunnel mutation"
echo "NO storage mutation"
echo "NO worker/model/scheduler/DB mutation"
echo

test -f "$DOC"
grep -Fq "PVEW Quorum Architecture Decision Gate No-Apply" "$DOC"
grep -Fq "ClusterOfThings" "$DOC"
grep -Fq "Option A" "$DOC"
grep -Fq "Option B" "$DOC"
grep -Fq "Option C" "$DOC"
grep -Fq "Option D" "$DOC"
grep -Fq "Prefer Option A" "$DOC"
grep -Fq "CT204 remains stopped" "$DOC"
grep -Fq "Private storage remains manual-unlock-only" "$DOC"
grep -Fq "no worker/model/scheduler activation" "$DOC"
grep -Fq "CT203 still uses DHCP" "$DOC"
echo "PASS: decision doc required content present"

tmp_status="$(mktemp)"
trap 'rm -f "$tmp_status"' EXIT
status_http="$(curl -fsS --max-time 15 -o "$tmp_status" -w '%{http_code}' "$PUBLIC_BASE/system/status")"
echo "public_status_http=$status_http"
test "$status_http" = "200"

python3 - "$tmp_status" <<'PY'
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
if '"data_authority": true' in text or '"data_authority":true' in text:
    raise SystemExit("data_authority=true present")
print("PASS: public status expected nodes/policy present")
PY

echo "RESULT=PASS_PHASE_14J_NI_QUORUM_DECISION_GATE_SMOKE"
