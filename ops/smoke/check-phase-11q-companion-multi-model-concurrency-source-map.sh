#!/usr/bin/env bash
set -u

fail=0

echo "=== Phase 11Q smoke: Companion multi-model concurrency source map ==="

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root" || fail=1

DOC="docs/phase-11q-companion-multi-model-concurrency-source-map.md"

echo
echo "=== git baseline ==="
git log --oneline -5
git tag --points-at HEAD

echo
echo "=== doc marker checks ==="

require_doc() {
  label="$1"
  marker="$2"

  if grep -Fq "$marker" "$DOC"; then
    echo "PASS: $label"
  else
    echo "FAIL: missing $label"
    echo "marker: $marker"
    fail=1
  fi
}

require_doc "decision maker section" "Decision maker"
require_doc "model lane registry section" "Model lane registry"
require_doc "scheduler behavior section" "Scheduler behavior"
require_doc "worker behavior section" "Worker behavior"
require_doc "Ollama parallel bottleneck documented" "OLLAMA_NUM_PARALLEL=1"
require_doc "large model lane documented" "large"
require_doc "tiny model lane documented" "tiny"
require_doc "runtime unchanged" "Runtime changes"

echo
echo "=== source marker checks ==="

check_source() {
  label="$1"
  marker="$2"
  file="$3"

  if grep -Fq "$marker" "$file"; then
    echo "PASS: $label"
    grep -nF "$marker" "$file" | sed -n '1,5p'
  else
    echo "FAIL: missing $label"
    echo "marker: $marker"
    echo "file: $file"
    fail=1
  fi
}

check_source "jobs table exists" "CREATE TABLE IF NOT EXISTS jobs" edge_controller.py
check_source "jobs requested_model exists" "requested_model TEXT" edge_controller.py
check_source "worker max concurrency exists" "max_concurrent_jobs" edge_controller.py
check_source "worker current jobs exists" "current_jobs" edge_controller.py
check_source "worker queue depth exists" "queue_depth" edge_controller.py
check_source "worker requirement estimator exists" "def estimate_job_requirements" edge_controller.py
check_source "worker scorer exists" "def score_worker_for_job" edge_controller.py
check_source "study parser model_tier exists" '"model_tier"' edge_controller.py
check_source "study parser queue_lane exists" '"queue_lane"' edge_controller.py
check_source "queued chat route exists" '@app.post("/api/chat/queued")' edge_controller.py
check_source "frontend queued submit exists" '/api/chat/queued' frontend/wrapper-ui/app.js

echo
echo "=== optional CT101 runtime marker checks ==="

if tailscale ping --timeout=4s --c 1 100.88.245.33 >/tmp/phase11q-ct101-ping.txt 2>&1; then
  echo "PASS: CT101 reachable"

  ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=8 \
    -o StrictHostKeyChecking=accept-new \
    root@100.88.194.19 \
    'pct exec 101 -- bash -lc "
      if grep -Fq \"OLLAMA_NUM_PARALLEL=1\" /opt/llm-stack/docker-compose.yml; then
        echo \"PASS: CT101 Ollama currently has OLLAMA_NUM_PARALLEL=1\"
      else
        echo \"CHECK: CT101 Ollama OLLAMA_NUM_PARALLEL=1 not found\"
      fi

      if grep -Fq \"DEFAULT_MODEL=gemma4:e4b\" /opt/ai-platform/.env; then
        echo \"PASS: CT101 default model currently gemma4:e4b\"
      else
        echo \"CHECK: CT101 default model marker not found\"
      fi

      if curl -sS --max-time 8 http://100.88.245.33:11434/api/tags | grep -Eq \"qwen3:0.6b|qwen3:1.7b|gemma3:4b|gemma4:e4b\"; then
        echo \"PASS: Ollama model tags reachable\"
      else
        echo \"CHECK: Ollama model tags not confirmed\"
      fi
    "' || true
else
  echo "CHECK: CT101 not reachable; optional runtime marker check skipped"
  cat /tmp/phase11q-ct101-ping.txt || true
fi

echo
echo "=== router rollout remains parked ==="

python3 - <<'PYROUTER'
from pathlib import Path
import re
import sys

fail = 0

backend_files = [Path("edge_controller.py")]
frontend_files = [Path("frontend/wrapper-ui/app.js"), Path("frontend/wrapper-ui/index.html")]

def read(path):
    try:
        return path.read_text(errors="ignore")
    except Exception:
        return ""

backend_text = "\n".join(read(p) for p in backend_files)
frontend_text = "\n".join(read(p) for p in frontend_files)

print()
print("--- backend router dry-run env guard ---")
dry_env_pattern = re.compile(
    r"os\.(?:getenv|environ\.get)\([\"']EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY"
    r"|Environment=.*EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY"
    r"|EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY[A-Z0-9_]*="
)
if dry_env_pattern.search(backend_text):
    print("FAIL: backend router dry-run env marker found")
    fail = 1
else:
    print("PASS: no backend router dry-run env marker found")

print()
print("--- frontend router/rollout POST guard ---")
post_pattern = re.compile(
    r"fetch\([^)]*(router|rollout)"
    r"|method\s*:\s*[\"']POST[\"'][^;]*(router|rollout)"
    r"|(router|rollout)[^;]*method\s*:\s*[\"']POST[\"']",
    re.IGNORECASE | re.DOTALL,
)
if post_pattern.search(frontend_text):
    print("FAIL: frontend router/rollout POST runtime marker found")
    fail = 1
else:
    print("PASS: no frontend router/rollout POST runtime marker found")

print()
print("--- backend rollout/router mutation route guard ---")
mutation_pattern = re.compile(
    r"@.*\.(post|put|patch|delete)\([^)]*(router|rollout)"
    r"|route\([^)]*(router|rollout)[^)]*methods=[^)]*[\"'](POST|PUT|PATCH|DELETE)[\"']"
    r"|methods=[^)]*[\"'](POST|PUT|PATCH|DELETE)[\"'][^)]*(router|rollout)",
    re.IGNORECASE,
)

allowed = {
    '@app.post("/api/router/dry-run")',
    '@app.post("/system/router/dry-run")',
}

hits = []
for p in backend_files:
    for line_no, line in enumerate(read(p).splitlines(), 1):
        if mutation_pattern.search(line):
            stripped = line.strip()
            if stripped not in allowed:
                hits.append(f"{p}:{line_no}:{stripped}")

if hits:
    print("FAIL: non-dry-run rollout/router mutation runtime marker found")
    for hit in hits[:40]:
        print(hit)
    fail = 1
else:
    print("PASS: no non-dry-run rollout/router mutation runtime marker found")

sys.exit(fail)
PYROUTER

router_rc=$?
if [ "$router_rc" != "0" ]; then
  fail=1
fi

echo
echo "=== confirm docs/smoke changes only ==="
bad_status="$(
  git status --short \
    | grep -vE '^[ ?MADRCU]{1,2} docs/phase-11q-companion-multi-model-concurrency-source-map\.md$' \
    | grep -vE '^[ ?MADRCU]{1,2} ops/smoke/check-phase-11q-companion-multi-model-concurrency-source-map\.sh$' \
    || true
)"

git status --short

if [ -n "$bad_status" ]; then
  echo
  echo "FAIL: unexpected changed files detected"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 11Q docs/smoke files are changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11Q Companion multi-model concurrency source map smoke passed"
else
  echo "FAIL: Phase 11Q Companion multi-model concurrency source map smoke failed"
fi

exit "$fail"
