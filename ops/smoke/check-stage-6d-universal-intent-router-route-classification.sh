#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6D Universal Intent Router route classification smoke ==="

fail=0

mkdir -p docs/generated

doc6a="docs/stage-6a-universal-intent-router-foundation-plan.md"
doc6b="docs/stage-6b-universal-intent-router-input-surface-audit.md"
doc6c="docs/stage-6c-universal-intent-router-route-inventory.md"
doc6d="docs/stage-6d-universal-intent-router-route-classification.md"
inventory="docs/generated/stage-6c-route-inventory.txt"
classification="docs/generated/stage-6d-route-classification.tsv"

echo
echo "=== required docs and inventory ==="
for f in "$doc6a" "$doc6b" "$doc6c" "$doc6d" "$inventory"; do
  if [ -s "$f" ]; then
    echo "OK: $f"
  else
    echo "FAIL: missing or empty $f"
    fail=1
  fi
done

echo
echo "=== generate first-pass route classification ==="
python3 - <<'PY'
from pathlib import Path
import re

inventory = Path("docs/generated/stage-6c-route-inventory.txt")
out = Path("docs/generated/stage-6d-route-classification.tsv")

text = inventory.read_text(errors="replace").splitlines()

rows = []
section = None

route_re = re.compile(r'^(\d+):@app\.(get|post|put|patch|delete)\("([^"]+)"\)')

for line in text:
    if line.startswith("## FastAPI routes in edge_controller.py"):
        section = "edge_controller.py"
        continue
    if line.startswith("## Public gateway routes if present"):
        section = "public_gateway.py"
        continue
    if line.startswith("## Frontend fetch calls"):
        section = None
        continue
    if line.startswith("## HTML form/input/button references"):
        section = None
        continue

    if not section:
        continue

    m = route_re.match(line)
    if not m:
        continue

    line_no, method, path = m.groups()
    method = method.upper()
    p = path.lower()

    route_class = "direct_application"
    safety_class = "read_only" if method == "GET" else "user_content_write"
    router_candidate = "no"
    migration_priority = "not_planned"
    confirmation_required = "no"
    notes = "direct application route"

    if p.startswith("/internal/"):
        route_class = "internal_service"
        safety_class = "internal_worker_only"
        router_candidate = "no"
        migration_priority = "never_direct_router_execute"
        confirmation_required = "n/a"
        notes = "internal worker/queue service route"

    elif (
        p.startswith("/power/")
        or p in {"/system/pveso/boot", "/system/presence/apply-power-policy"}
        or p.startswith("/system/admin/")
        or p.startswith("/system/gpu/")
        or p.startswith("/system/retention/")
        or p.startswith("/api/system/retention/")
        or p.startswith("/system/credits/")
    ):
        route_class = "admin_system"
        if method == "GET" or p.endswith("-plan") or p.endswith("/status") or "catalog" in p or "quote" in p or "sessions" in p or "dry-run" in p:
            safety_class = "infrastructure_read" if (p.startswith("/power/") or p.startswith("/system/gpu/") or p.startswith("/system/retention/") or p.startswith("/api/system/retention/")) else "admin_read"
            confirmation_required = "no"
        else:
            safety_class = "infrastructure_write_confirmed" if (p.startswith("/power/") or p.startswith("/system/pveso/") or p.startswith("/system/gpu/")) else "admin_write_confirmed"
            confirmation_required = "yes"
        router_candidate = "no"
        migration_priority = "never_direct_router_execute"
        notes = "guarded admin/system route"

    elif (
        "/auth/" in p
        or p.startswith("/api/auth/")
        or p.startswith("/system/session/login")
        or p.startswith("/system/session/logout")
        or p.startswith("/system/session/register")
        or p.startswith("/system/session/forgot-password")
        or p.startswith("/system/session/reset-password")
        or p.startswith("/system/session/change-password")
        or p.startswith("/system/session/logout-safe")
        or p.startswith("/system/account/bootstrap-admin")
    ):
        route_class = "auth_security"
        safety_class = "auth_security"
        router_candidate = "no"
        migration_priority = "never_direct_router_execute"
        confirmation_required = "yes" if method != "GET" else "no"
        notes = "authentication/security route"

    elif (
        p.endswith("/study/intent/parse")
        or p.endswith("/study/session/command")
        or p.endswith("/companion/chat")
        or p in {"/api/chat/queued", "/public/chat/queued"}
    ):
        route_class = "router_candidate"
        safety_class = "user_content_write"
        router_candidate = "yes"
        migration_priority = "priority_1"
        confirmation_required = "no"
        notes = "natural-language or flexible command input"

    elif (
        p.endswith("/companion/study/grade")
        or p.endswith("/study/decks")
        or "/study/decks/" in p
        or "/study/cards/" in p
        or p.endswith("/study/session/start")
        or p.endswith("/study/session/pause")
        or p.endswith("/study/session/resume")
        or p.endswith("/study/session/stop")
    ):
        route_class = "direct_application"
        safety_class = "user_content_write" if method != "GET" else "read_only"
        router_candidate = "maybe_later"
        migration_priority = "priority_2_or_3"
        confirmation_required = "yes" if method in {"DELETE"} else "no"
        notes = "study app route; router may assist later but should not replace handler now"

    elif (
        p.startswith("/system/status")
        or p.startswith("/system/local-health")
        or p.startswith("/health")
        or p.startswith("/public/status")
        or p.endswith("/queue/status")
        or p.endswith("/queue/summary")
        or p.startswith("/workers/registry")
        or p.startswith("/workers/events")
        or p.startswith("/system/presence/power-policy")
        or p.startswith("/system/account/me")
        or p.startswith("/system/account/credits")
        or p.startswith("/system/account/credit-pools")
        or p.startswith("/public/me")
    ):
        route_class = "direct_application"
        safety_class = "read_only"
        router_candidate = "no"
        migration_priority = "not_planned"
        confirmation_required = "no"
        notes = "read-only status/account route"

    elif "presence" in p:
        route_class = "direct_application"
        safety_class = "user_content_write"
        router_candidate = "no"
        migration_priority = "not_planned"
        confirmation_required = "no"
        notes = "presence heartbeat route"

    elif method == "DELETE":
        route_class = "direct_application"
        safety_class = "user_content_write"
        router_candidate = "no"
        migration_priority = "never_direct_router_execute"
        confirmation_required = "yes"
        notes = "delete route; explicit app handler only"

    rows.append(
        {
            "source": section,
            "line": line_no,
            "method": method,
            "path": path,
            "route_class": route_class,
            "safety_class": safety_class,
            "router_candidate": router_candidate,
            "migration_priority": migration_priority,
            "confirmation_required": confirmation_required,
            "notes": notes,
        }
    )

headers = [
    "source",
    "line",
    "method",
    "path",
    "route_class",
    "safety_class",
    "router_candidate",
    "migration_priority",
    "confirmation_required",
    "notes",
]

out.parent.mkdir(parents=True, exist_ok=True)
with out.open("w", encoding="utf-8") as f:
    f.write("\t".join(headers) + "\n")
    for row in rows:
        f.write("\t".join(str(row[h]).replace("\t", " ") for h in headers) + "\n")

print(f"wrote {out} with {len(rows)} classified backend/gateway routes")
PY

if [ -s "$classification" ]; then
  echo "OK: generated $classification"
else
  echo "FAIL: classification file not generated"
  fail=1
fi

echo
echo "=== classification counts ==="
route_count="$(tail -n +2 "$classification" | wc -l | tr -d ' ')"
router_candidate_count="$(awk -F '\t' 'NR>1 && $7=="yes"{c++} END{print c+0}' "$classification")"
maybe_later_count="$(awk -F '\t' 'NR>1 && $7=="maybe_later"{c++} END{print c+0}' "$classification")"
admin_count="$(awk -F '\t' 'NR>1 && $5=="admin_system"{c++} END{print c+0}' "$classification")"
internal_count="$(awk -F '\t' 'NR>1 && $5=="internal_service"{c++} END{print c+0}' "$classification")"
auth_count="$(awk -F '\t' 'NR>1 && $5=="auth_security"{c++} END{print c+0}' "$classification")"

echo "route_count=$route_count"
echo "router_candidate_count=$router_candidate_count"
echo "maybe_later_count=$maybe_later_count"
echo "admin_count=$admin_count"
echo "internal_count=$internal_count"
echo "auth_count=$auth_count"

if [ "${route_count:-0}" -lt 100 ]; then
  echo "FAIL: expected at least 100 classified routes"
  fail=1
fi

if [ "${router_candidate_count:-0}" -lt 1 ]; then
  echo "FAIL: expected at least one router candidate"
  fail=1
fi

if [ "${admin_count:-0}" -lt 1 ]; then
  echo "FAIL: expected at least one admin/system route"
  fail=1
fi

if [ "${internal_count:-0}" -lt 1 ]; then
  echo "FAIL: expected at least one internal service route"
  fail=1
fi

if [ "${auth_count:-0}" -lt 1 ]; then
  echo "FAIL: expected at least one auth/security route"
  fail=1
fi

echo
echo "=== ensure backup frontend files are not classified as routes ==="
if grep -q 'app.js.bak' "$classification"; then
  echo "FAIL: backup frontend files leaked into route classification"
  fail=1
else
  echo "OK: no backup frontend files in route classification"
fi

echo
echo "=== required Stage 6D markers ==="
for marker in \
  "router_candidate" \
  "direct_application" \
  "internal_service" \
  "admin_system" \
  "auth_security" \
  "Router migration rules" \
  "must not directly execute"
do
  if grep -q "$marker" "$doc6d"; then
    echo "OK: found marker: $marker"
  else
    echo "FAIL: missing marker: $marker"
    fail=1
  fi
done

echo
echo "=== required classified route examples ==="
for route in \
  "/api/study/intent/parse" \
  "/api/study/session/command" \
  "/api/companion/chat" \
  "/api/chat/queued" \
  "/power/auto/tick" \
  "/internal/laptop-queue/workers/heartbeat" \
  "/system/session/login"
do
  if grep -q "$route" "$classification"; then
    echo "OK: classified route: $route"
  else
    echo "FAIL: missing classified route: $route"
    fail=1
  fi
done

echo
echo "=== runtime code should not be modified for this planning stage ==="
if git diff --name-only | grep -E '(^edge_controller.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' >/dev/null; then
  echo "FAIL: runtime or systemd files are modified:"
  git diff --name-only | grep -E '(^edge_controller.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' || true
  fail=1
else
  echo "OK: no runtime/systemd file modifications detected"
fi

echo
echo "=== classification preview ==="
sed -n '1,120p' "$classification"

echo
echo "=== git status ==="
git status --short

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 6D Universal Intent Router route classification smoke passed"
else
  echo "FAIL: Stage 6D Universal Intent Router route classification smoke failed"
fi

exit "$fail"
