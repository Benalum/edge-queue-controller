#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-nk-pvew-quorum-pre-apply-inventory-no-apply.md"
PUBLIC_BASE="${PUBLIC_BASE:-https://alexhartel.com}"
PUBLIC_APP_PATH="${PUBLIC_APP_PATH:-/app.js?v=2026061814jlbr2}"
EXPECTED_PUBLIC_APP_SHA="${EXPECTED_PUBLIC_APP_SHA:-afc8e99b17e3bd76da364241bad19fd4290a6c02631b1b5802e411d25f004d8d}"

echo "=== Phase 14J-NK smoke R4: compact no-apply checkpoint ==="
echo "MUTATION_SCOPE=read_only_smoke"
echo "NO live infra mutation"
echo "NO pvecm expected mutation"
echo "NO pvecm delnode"
echo "NO corosync/pve cluster config mutation"
echo "NO CT/VM start/stop/restart"
echo "NO nginx reload/restart"
echo "NO Cloudflare/DNS/tunnel mutation"
echo "NO storage mutation"
echo "NO worker/model/scheduler/DB mutation"
echo

test -f "$DOC"
grep -Fq "PVEW Quorum Pre-Apply Inventory No-Apply" "$DOC"
grep -Fq "full NK inventory block exceeded" "$DOC"
grep -Fq "ClusterOfThings" "$DOC"
grep -Fq "pvecm expected 1" "$DOC"
grep -Fq "pvecm delnode" "$DOC"
grep -Fq "CT203 workers offline" "$DOC"
grep -Fq "Private storage locked/unmounted" "$DOC"
grep -Fq "No live infrastructure mutation" "$DOC"
echo "PASS: compact NK doc content present"

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
print("PASS: public status expected nodes/policy present")
PY

curl -fsS --max-time 20 -H 'cache-control: no-cache' "$PUBLIC_BASE$PUBLIC_APP_PATH" -o "$tmp_app"
public_app_sha="$(sha256sum "$tmp_app" | awk '{print $1}')"
echo "public_app_sha=$public_app_sha"
test "$public_app_sha" = "$EXPECTED_PUBLIC_APP_SHA"
grep -Fq 'CT203/controller-owned' "$tmp_app"

if grep -Fq 'laptop controller-owned' "$tmp_app"; then
  echo "FAIL: stale laptop controller-owned text present"
  exit 1
fi

echo "PASS: public app hash/copy expected"
echo "RESULT=PASS_PHASE_14J_NK_COMPACT_R4_SMOKE"
