#!/usr/bin/env bash
set -u

echo "=== Stage 8H smoke: frontend router shadow-read hook audit ==="

fail=0
DOC="docs/stage-8h-frontend-router-shadow-read-hook-audit.md"
REPORT="docs/generated/stage-8h-frontend-router-shadow-read-hook-audit.json"
APP_JS="frontend/wrapper-ui/app.js"

if [ ! -f "$DOC" ]; then
  echo "FAIL: missing $DOC"
  fail=1
else
  echo "OK: found $DOC"
fi

for marker in \
  "Frontend Router Shadow-Read Hook Audit" \
  "Shadow-Read Principle" \
  "Candidate Shadow-Read Hook Points" \
  "Generated Report" \
  "Stage 8I"; do
  if grep -q "$marker" "$DOC"; then
    echo "OK: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

if [ ! -f "$APP_JS" ]; then
  echo "FAIL: missing $APP_JS"
  fail=1
else
  echo "OK: found $APP_JS"
fi

echo
echo "=== generate frontend hook audit report ==="
python3 - <<'PY' | tee /tmp/stage8h-generate-report.log
from pathlib import Path
import json
import re

app_path = Path("frontend/wrapper-ui/app.js")
report_path = Path("docs/generated/stage-8h-frontend-router-shadow-read-hook-audit.json")

text = app_path.read_text()
lines = text.splitlines()

patterns = {
    "study_command_api_calls": r"/api/study/session/command",
    "study_route_or_surface_markers": r"Study|study",
    "companion_route_or_surface_markers": r"Companion|companion|/companion",
    "shared_api_helper_markers": r"\bapi\s*\(|async function api|function api",
    "submit_or_send_markers": r"submit|send|message|command",
    "router_markers": r"router|decision_contract|dry-run|dry_run",
}

def collect(pattern, limit=80):
    rx = re.compile(pattern)
    hits = []
    for i, line in enumerate(lines, start=1):
        if rx.search(line):
            hits.append(
                {
                    "line": i,
                    "text": line.strip()[:240],
                }
            )
    return hits[:limit], len(hits)

sections = {}
for name, pattern in patterns.items():
    hits, total = collect(pattern)
    sections[name] = {
        "pattern": pattern,
        "total_matches": total,
        "sample_matches": hits,
    }

study_call_lines = [h["line"] for h in sections["study_command_api_calls"]["sample_matches"]]
companion_lines = [h["line"] for h in sections["companion_route_or_surface_markers"]["sample_matches"]]
api_lines = [h["line"] for h in sections["shared_api_helper_markers"]["sample_matches"]]

candidate_hooks = []

for line in study_call_lines[:20]:
    candidate_hooks.append(
        {
            "surface": "study",
            "line": line,
            "hook_type": "near_existing_study_command_api_call",
            "future_behavior": "shadow-read decision_contract only; do not replace existing Study command dispatch",
        }
    )

for line in companion_lines[:20]:
    candidate_hooks.append(
        {
            "surface": "companion",
            "line": line,
            "hook_type": "near_companion_surface_or_submit_flow",
            "future_behavior": "shadow-read decision_contract only; do not replace Companion chat behavior",
        }
    )

for line in api_lines[:10]:
    candidate_hooks.append(
        {
            "surface": "shared",
            "line": line,
            "hook_type": "shared_api_helper_observation_point",
            "future_behavior": "only consider passive observation; avoid changing API semantics",
        }
    )

report = {
    "stage": "8H",
    "source_file": str(app_path),
    "safety": {
        "runtime_code_modified": False,
        "live_router_enabled": False,
        "dispatch_enabled": False,
        "models_called": False,
    },
    "sections": sections,
    "candidate_hooks": candidate_hooks,
    "recommendation": {
        "stage_8i": "Add a source-only disabled-by-default frontend shadow-read helper plan or no-op stub only if behavior-preserving.",
        "do_not_do_yet": [
            "Do not replace Study command calls.",
            "Do not replace Companion submit flow.",
            "Do not enable live router dispatch.",
            "Do not make router output user-visible yet.",
        ],
    },
}

report_path.parent.mkdir(parents=True, exist_ok=True)
report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")

print(f"wrote_report={report_path}")
print(f"study_command_api_call_count={sections['study_command_api_calls']['total_matches']}")
print(f"companion_marker_count={sections['companion_route_or_surface_markers']['total_matches']}")
print(f"shared_api_helper_marker_count={sections['shared_api_helper_markers']['total_matches']}")
print(f"candidate_hook_count={len(candidate_hooks)}")
print("PASS: Stage 8H generated frontend hook audit report")
PY

if ! grep -q "PASS: Stage 8H generated frontend hook audit report" /tmp/stage8h-generate-report.log; then
  echo "FAIL: report generation failed"
  fail=1
fi

echo
echo "=== validate generated report ==="
if [ -f "$REPORT" ]; then
  python3 -m json.tool "$REPORT" >/dev/null
  grep -q '"stage": "8H"' "$REPORT" || fail=1
  grep -q '"candidate_hooks"' "$REPORT" || fail=1
  grep -q '"study_command_api_calls"' "$REPORT" || fail=1
  grep -q '"companion_route_or_surface_markers"' "$REPORT" || fail=1
  echo "OK: generated report valid"
else
  echo "FAIL: missing generated report $REPORT"
  fail=1
fi

study_count="$(python3 - <<'PY'
import json
from pathlib import Path
p = Path("docs/generated/stage-8h-frontend-router-shadow-read-hook-audit.json")
if not p.exists():
    print("0")
else:
    data = json.loads(p.read_text())
    print(data["sections"]["study_command_api_calls"]["total_matches"])
PY
)"

candidate_count="$(python3 - <<'PY'
import json
from pathlib import Path
p = Path("docs/generated/stage-8h-frontend-router-shadow-read-hook-audit.json")
if not p.exists():
    print("0")
else:
    data = json.loads(p.read_text())
    print(len(data["candidate_hooks"]))
PY
)"

echo "study_command_api_call_count=$study_count"
echo "candidate_hook_count=$candidate_count"

if [ "$study_count" = "0" ]; then
  echo "FAIL: expected at least one Study command API call marker"
  fail=1
fi

if [ "$candidate_count" = "0" ]; then
  echo "FAIL: expected at least one candidate hook"
  fail=1
fi

echo
echo "=== live router endpoint must remain disabled ==="
for path in /api/router/dry-run /system/router/dry-run /router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8h-${path//\//_}.out" -w "%{http_code}" \
    -X POST "http://127.0.0.1:7070${path}" \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
  echo "$path code=$code"
  sed -n '1,8p' "/tmp/stage8h-${path//\//_}.out" || true

  if [ "$code" != "404" ]; then
    echo "FAIL: $path should remain disabled/not found"
    fail=1
  fi
done

echo
echo "=== platform remains clean ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .

curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage8h-system-status.json
jq '{
  overall_state,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker"))
}' /tmp/stage8h-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8h-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8h-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8h-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8h-system-status.json)"

echo "overall_state=$overall_state"
echo "queue_failed=$queue_failed"
echo "queue_queued=$queue_queued"
echo "queue_running=$queue_running"

if [ "$overall_state" != "online" ]; then
  echo "FAIL: platform should remain online"
  fail=1
fi

if [ "$queue_failed" != "0" ] || [ "$queue_queued" != "0" ] || [ "$queue_running" != "0" ]; then
  echo "FAIL: queue should remain clean"
  fail=1
fi

echo
echo "=== timer safety unchanged ==="
echo "legacy_enabled=$(systemctl is-enabled edge-queue-scheduler-tick.timer || true)"
echo "legacy_active=$(systemctl is-active edge-queue-scheduler-tick.timer || true)"
echo "power_auto_active=$(systemctl is-active edge-queue-power-auto-tick.timer || true)"
echo "remediation_active=$(systemctl is-active edge-queue-remediation-tick.timer || true)"

echo
echo "=== verify no runtime frontend/source files modified ==="
runtime_changed="$(git status --short | awk '{print $2}' | grep -E '^(frontend/|edge_controller.py|edge_intent_router.py|backend/|public_gateway.py)' || true)"
if [ -n "$runtime_changed" ]; then
  echo "FAIL: runtime/source files changed unexpectedly:"
  echo "$runtime_changed"
  fail=1
else
  echo "OK: no runtime/source file modifications"
fi

echo
echo "=== final repo status ==="
git status --short

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 8H frontend router shadow-read hook audit verified"
else
  echo "FAIL: Stage 8H smoke found an issue"
fi
