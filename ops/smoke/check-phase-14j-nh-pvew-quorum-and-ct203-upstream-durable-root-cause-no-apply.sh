#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-nh-pvew-quorum-and-ct203-upstream-durable-root-cause-no-apply.md"
PUBLIC_BASE="${PUBLIC_BASE:-https://alexhartel.com}"
EXPECTED_PUBLIC_APP_SHA="${EXPECTED_PUBLIC_APP_SHA:-afc8e99b17e3bd76da364241bad19fd4290a6c02631b1b5802e411d25f004d8d}"
PUBLIC_APP_PATH="${PUBLIC_APP_PATH:-/app.js?v=2026061814jlbr2}"

echo "=== Phase 14J-NH smoke R2: durable root-cause checkpoint ==="
echo "MUTATION_SCOPE=read_only_smoke"
echo "NO live infra mutation"
echo "NO pvecm expected mutation"
echo "NO CT/VM start/stop/restart"
echo "NO nginx reload/restart"
echo "NO Cloudflare/DNS/tunnel mutation"
echo "NO storage mutation"
echo "NO worker/model/scheduler/DB mutation"
echo

test -f "$DOC"
grep -Fq "PVEW Quorum and CT203 Upstream Durable Root-Cause Review" "$DOC"
grep -Fq "ClusterOfThings" "$DOC"
grep -Fq "pvecm expected 1" "$DOC"
grep -Fq "CT204 remains stopped" "$DOC"
grep -Fq "Private storage remains locked/unmounted" "$DOC"
grep -Fq "HTTP 200" "$DOC"
grep -Fq "Do not proceed to PVESO worker/model readiness yet" "$DOC"
grep -Fq "CT203 addressing" "$DOC"
grep -Fq "quorum design" "$DOC"
echo "PASS: doc required content present"

tmp_status="$(mktemp)"
tmp_app="$(mktemp)"
trap 'rm -f "$tmp_status" "$tmp_app"' EXIT

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

curl -fsS --max-time 20 -H 'cache-control: no-cache' "$PUBLIC_BASE$PUBLIC_APP_PATH" -o "$tmp_app"
public_app_sha="$(sha256sum "$tmp_app" | awk '{print $1}')"
echo "public_app_sha=$public_app_sha"
test "$public_app_sha" = "$EXPECTED_PUBLIC_APP_SHA"

if grep -Fq 'laptop controller-owned' "$tmp_app"; then
  echo "FAIL: stale laptop controller-owned text present"
  exit 1
fi

grep -Fq 'CT203/controller-owned' "$tmp_app"
echo "PASS: public app hash/copy expected"

echo "RESULT=PASS_PHASE_14J_NH_DURABLE_ROOT_CAUSE_CHECKPOINT_SMOKE_R2"
