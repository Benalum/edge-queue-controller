#!/usr/bin/env bash
set -u

fail=0
rollback_needed=0

pass() {
  echo "PASS: $1"
}

check_fail() {
  echo "CHECK: $1"
  fail=1
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
cd "$ROOT" || {
  echo "CHECK: could not cd into repo root"
  exit 1
}

REPORT="docs/generated/stage-9n-controlled-operator-gated-browser-shadow-read-activation-rollback.md"
EVIDENCE="docs/generated/stage-9n-controlled-operator-gated-browser-shadow-read-activation-rollback-evidence.json"
SMOKE="ops/smoke/check-stage-9n-controlled-operator-gated-browser-shadow-read-activation-rollback.sh"

STAGE9K_EVIDENCE="docs/generated/stage-9k-disabled-operator-gated-browser-shadow-read-activation-boundary-evidence.json"
STAGE9L_EVIDENCE="docs/generated/stage-9l-live-served-disabled-operator-gate-verification-evidence.json"
STAGE9M_REPORT="docs/generated/stage-9m-operator-gated-controlled-activation-plan.md"

APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
FRONTEND_BASE="http://127.0.0.1:8787"
STATUS_URL="http://127.0.0.1:8787/api/system/status"

DROPIN_DIR="/etc/systemd/system/edge-queue-controller.service.d"
DROPIN="$DROPIN_DIR/87-stage9n-router-dry-run.conf"

LIVE_APP="/tmp/stage9n-live-app.js"
LIVE_STUB="/tmp/stage9n-live-router-shadow-read-stub.js"
LIVE_BLOCKS="/tmp/stage9n-live-app-blocks.js"
OPERATOR_GATE_RESULT="/tmp/stage9n-controlled-operator-gated-result.json"

export STAGE9N_FINAL_RESULT="unknown"
export STAGE9N_HEALTH_BEFORE="unknown"
export STAGE9N_POST_BEFORE="unknown"
export STAGE9N_QUEUE_BEFORE_CLEAN="unknown"
export STAGE9N_HEALTH_ENABLED="unknown"
export STAGE9N_POST_ENABLED="unknown"
export STAGE9N_BROWSER_REQUESTS="unknown"
export STAGE9N_BROWSER_STATUS="unknown"
export STAGE9N_BROWSER_OK="unknown"
export STAGE9N_BROWSER_SURFACE="unknown"
export STAGE9N_BROWSER_DRY_RUN="unknown"
export STAGE9N_DISPATCH_REQUESTED="unknown"
export STAGE9N_DISPATCH_PERFORMED="unknown"
export STAGE9N_BODY_DISPATCH_PERFORMED="unknown"
export STAGE9N_OPERATOR_GATE_ENABLED_IN_VM="unknown"
export STAGE9N_OPERATOR_GATE_RESTORED_FALSE_IN_VM="unknown"
export STAGE9N_QUEUE_ENABLED_CLEAN="unknown"
export STAGE9N_HEALTH_AFTER="unknown"
export STAGE9N_POST_AFTER="unknown"
export STAGE9N_ROLLBACK_ENV_ABSENT="unknown"
export STAGE9N_QUEUE_AFTER_CLEAN="unknown"

write_evidence() {
  python3 - "$EVIDENCE" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
data = {
    "stage": "9N",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "controlled operator-gated browser shadow-read activation and rollback",
    "health_before": os.environ.get("STAGE9N_HEALTH_BEFORE"),
    "post_before": os.environ.get("STAGE9N_POST_BEFORE"),
    "queue_before_clean": os.environ.get("STAGE9N_QUEUE_BEFORE_CLEAN"),
    "health_enabled": os.environ.get("STAGE9N_HEALTH_ENABLED"),
    "post_enabled": os.environ.get("STAGE9N_POST_ENABLED"),
    "browser_requests": os.environ.get("STAGE9N_BROWSER_REQUESTS"),
    "browser_status": os.environ.get("STAGE9N_BROWSER_STATUS"),
    "browser_ok": os.environ.get("STAGE9N_BROWSER_OK"),
    "browser_surface": os.environ.get("STAGE9N_BROWSER_SURFACE"),
    "browser_dry_run": os.environ.get("STAGE9N_BROWSER_DRY_RUN"),
    "dispatch_requested": os.environ.get("STAGE9N_DISPATCH_REQUESTED"),
    "dispatch_performed": os.environ.get("STAGE9N_DISPATCH_PERFORMED"),
    "body_dispatch_performed": os.environ.get("STAGE9N_BODY_DISPATCH_PERFORMED"),
    "operator_gate_enabled_in_vm": os.environ.get("STAGE9N_OPERATOR_GATE_ENABLED_IN_VM"),
    "operator_gate_restored_false_in_vm": os.environ.get("STAGE9N_OPERATOR_GATE_RESTORED_FALSE_IN_VM"),
    "queue_enabled_clean": os.environ.get("STAGE9N_QUEUE_ENABLED_CLEAN"),
    "health_after": os.environ.get("STAGE9N_HEALTH_AFTER"),
    "post_after": os.environ.get("STAGE9N_POST_AFTER"),
    "rollback_env_absent": os.environ.get("STAGE9N_ROLLBACK_ENV_ABSENT"),
    "queue_after_clean": os.environ.get("STAGE9N_QUEUE_AFTER_CLEAN"),
    "final_result": os.environ.get("STAGE9N_FINAL_RESULT"),
}
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {path}")
PY
}

wait_for_health() {
  label="$1"
  tries=30
  code="000"
  while [ "$tries" -gt 0 ]; do
    code="$(curl -sS --max-time 3 -o "/tmp/stage9n-health-${label}.out" -w "%{http_code}" "$BASE/health" 2>"/tmp/stage9n-health-${label}.err" || printf 'curl_failed')"
    if [ "$code" = "200" ]; then
      echo "$code"
      return 0
    fi
    tries=$((tries - 1))
    sleep 1
  done
  echo "$code"
  return 1
}

queue_clean_check() {
  label="$1"
  out="/tmp/stage9n-system-status-${label}.json"
  err="/tmp/stage9n-system-status-${label}.err"

  queue_code="$(curl -sS --max-time 5 -o "$out" -w "%{http_code}" "$STATUS_URL" 2>"$err" || printf 'curl_failed')"
  echo "queue_status_${label}_code=$queue_code"

  if [ "$queue_code" != "200" ]; then
    return 3
  fi

  python3 - "$out" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

matches = []

def walk(value, label="$"):
    if isinstance(value, dict):
        if all(k in value for k in ("queued", "running", "failed")):
            matches.append((label, value.get("queued"), value.get("running"), value.get("failed")))
        for k, v in value.items():
            walk(v, f"{label}.{k}")
    elif isinstance(value, list):
        for i, v in enumerate(value):
            walk(v, f"{label}[{i}]")

walk(data)

if not matches:
    print("MISSING_QUEUE_TRIPLE")
    sys.exit(3)

for label, queued, running, failed in matches:
    print(f"{label}: queued={queued} running={running} failed={failed}")

clean = any(str(q) == "0" and str(r) == "0" and str(f) == "0" for _, q, r, f in matches)
sys.exit(0 if clean else 2)
PY
}

rollback_backend() {
  if [ "$rollback_needed" = "1" ]; then
    echo
    echo "=== rollback: remove Stage 9N backend dry-run drop-in and restart controller ==="
    sudo rm -f "$DROPIN" || true
    sudo systemctl daemon-reload || true
    sudo systemctl restart edge-queue-controller || true

    health_after="$(wait_for_health after-rollback || true)"
    STAGE9N_HEALTH_AFTER="$health_after"
    export STAGE9N_HEALTH_AFTER
    echo "health_after=$health_after"

    controller_env_after="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
    if printf '%s\n' "$controller_env_after" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
      STAGE9N_ROLLBACK_ENV_ABSENT="false"
      export STAGE9N_ROLLBACK_ENV_ABSENT
      check_fail "rollback failed: backend dry-run env still enabled"
    else
      STAGE9N_ROLLBACK_ENV_ABSENT="true"
      export STAGE9N_ROLLBACK_ENV_ABSENT
      pass "backend dry-run env absent after rollback"
    fi

    post_after="$(curl -sS --max-time 5 -X POST \
      -H 'Content-Type: application/json' \
      -d '{"text":"stage9n rollback check","source":"stage9n","surface":"backend-only"}' \
      -o /tmp/stage9n-router-post-after.out \
      -w "%{http_code}" \
      "$BASE/api/router/dry-run" 2>/tmp/stage9n-router-post-after.err || printf 'curl_failed')"
    STAGE9N_POST_AFTER="$post_after"
    export STAGE9N_POST_AFTER
    echo "post_after=$post_after"

    if [ "$post_after" = "404" ]; then
      pass "POST /api/router/dry-run returned HTTP 404 after rollback"
    else
      check_fail "POST /api/router/dry-run did not return HTTP 404 after rollback"
    fi

    if queue_clean_check after; then
      STAGE9N_QUEUE_AFTER_CLEAN="true"
      export STAGE9N_QUEUE_AFTER_CLEAN
      pass "queue clean after rollback"
    else
      STAGE9N_QUEUE_AFTER_CLEAN="false"
      export STAGE9N_QUEUE_AFTER_CLEAN
      check_fail "queue not clean after rollback"
    fi

    rollback_needed=0
  fi
}

trap 'rollback_backend; STAGE9N_FINAL_RESULT="fail"; export STAGE9N_FINAL_RESULT; write_evidence' INT TERM

echo "=== Stage 9N smoke: controlled operator-gated browser shadow-read activation and rollback ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 9N report exists" || check_fail "Stage 9N report missing"
[ -x "$SMOKE" ] && pass "Stage 9N smoke script is executable" || check_fail "Stage 9N smoke script missing or not executable"

for needle in \
  "Stage 9N performs one controlled operator-gated browser shadow-read activation and rollback." \
  "Stage 9N temporarily enables backend router dry-run." \
  "Stage 9N restarts edge-queue-controller for activation and rollback." \
  "Stage 9N loads live-served router_shadow_read_stub.js." \
  "Stage 9N loads the live-served Stage 9D browser-surface bridge block." \
  "Stage 9N loads the live-served Stage 9K operator gate block." \
  "Stage 9N enables browser shadow-read flags only inside a Node VM." \
  "Stage 9N enables the operator gate only inside a Node VM." \
  "Stage 9N calls requestBrowserSurfaceRouterShadowRead exactly once." \
  "Stage 9N confirms exactly one request is sent." \
  "Stage 9N confirms dry_run = true." \
  "Stage 9N confirms dispatch_requested = false." \
  "Stage 9N confirms dispatch_performed = false." \
  "POST /api/router/dry-run returns HTTP 404 before activation." \
  "POST /api/router/dry-run returns HTTP 200." \
  "POST /api/router/dry-run returns HTTP 404 after rollback."
do
  if grep -Fq "$needle" "$REPORT"; then
    pass "report contains: $needle"
  else
    check_fail "report missing required text: $needle"
  fi
done

echo
echo "=== repo cleanliness check allowing only Stage 9N generated files ==="
dirty="$(git status --short)"
unexpected="$(printf '%s\n' "$dirty" | grep -vE '^\?\? docs/generated/stage-9n-controlled-operator-gated-browser-shadow-read-activation-rollback(\.md|-evidence\.json)$|^\?\? ops/smoke/check-stage-9n-controlled-operator-gated-browser-shadow-read-activation-rollback\.sh$|^$' || true)"
if [ -z "$unexpected" ]; then
  pass "repo has no unexpected dirty files"
else
  check_fail "repo has unexpected dirty files"
  printf '%s\n' "$unexpected"
fi

echo
echo "=== Stage 9K/9L/9M evidence and plan checks ==="
[ -f "$STAGE9K_EVIDENCE" ] && pass "Stage 9K evidence exists" || check_fail "Stage 9K evidence missing"
[ -f "$STAGE9L_EVIDENCE" ] && pass "Stage 9L evidence exists" || check_fail "Stage 9L evidence missing"
[ -f "$STAGE9M_REPORT" ] && pass "Stage 9M report exists" || check_fail "Stage 9M report missing"

python3 - "$STAGE9K_EVIDENCE" "$STAGE9L_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

stage9k = Path(sys.argv[1])
stage9l = Path(sys.argv[2])

checks = [
    (stage9k, {
        "final_result": {"pass"},
        "local_disabled_runtime": {"pass"},
        "post_code": {"404"},
        "env_absent": {"true", "True"},
        "queue_clean": {"true", "True"},
    }),
    (stage9l, {
        "final_result": {"pass"},
        "live_app_code": {"200"},
        "live_stub_code": {"200"},
        "live_disabled_runtime": {"pass"},
        "post_code": {"404"},
        "env_absent": {"true", "True"},
        "queue_clean": {"true", "True"},
    }),
]

bad = []
for path, expected in checks:
    if not path.exists():
        bad.append((str(path), "missing", "missing"))
        continue
    data = json.loads(path.read_text(encoding="utf-8"))
    for key, allowed in expected.items():
        actual = str(data.get(key))
        print(f"{path.name}:{key}={actual}")
        if actual not in allowed:
            bad.append((f"{path.name}:{key}", sorted(allowed), actual))

if bad:
    print("CHECK: evidence validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 9K and Stage 9L evidence values confirmed")
PY
if [ "$?" = "0" ]; then
  pass "Stage 9K/9L evidence values confirmed"
else
  check_fail "Stage 9K/9L evidence validation failed"
fi

echo
echo "=== local frontend pre-activation checks ==="
[ -f "$APP_JS" ] && pass "app.js exists" || check_fail "missing $APP_JS"
[ -f "$STUB" ] && pass "router shadow-read stub exists" || check_fail "missing $STUB"

grep -q "EdgeRouterShadowReadSurface" "$APP_JS" 2>/dev/null \
  && pass "app.js contains EdgeRouterShadowReadSurface" \
  || check_fail "app.js missing EdgeRouterShadowReadSurface"

grep -q "EdgeRouterShadowReadOperatorGate" "$APP_JS" 2>/dev/null \
  && pass "app.js contains EdgeRouterShadowReadOperatorGate" \
  || check_fail "app.js missing EdgeRouterShadowReadOperatorGate"

grep -q "OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false" "$APP_JS" 2>/dev/null \
  && pass "operator gate default false marker exists" \
  || check_fail "operator gate default false marker missing"

grep -q "operator_browser_shadow_read_activation_disabled" "$APP_JS" 2>/dev/null \
  && pass "operator gate disabled reason exists" \
  || check_fail "operator gate disabled reason missing"

if grep -q "/api/router/dry-run" "$APP_JS" 2>/dev/null; then
  check_fail "app.js directly contains /api/router/dry-run"
  grep -n "/api/router/dry-run" "$APP_JS" | sed -n '1,80p'
else
  pass "app.js contains no /api/router/dry-run"
fi

grep -q 'const ROUTER_DRY_RUN_ENDPOINT = "/api/router/dry-run";' "$STUB" 2>/dev/null \
  && pass "stub contains backend dry-run endpoint boundary" \
  || check_fail "stub missing backend dry-run endpoint boundary"

grep -q "const ROUTER_SHADOW_READ_ENABLED = false;" "$STUB" 2>/dev/null \
  && pass "ROUTER_SHADOW_READ_ENABLED remains false" \
  || check_fail "ROUTER_SHADOW_READ_ENABLED=false marker missing"

grep -q "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;" "$STUB" 2>/dev/null \
  && pass "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT remains false" \
  || check_fail "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT=false marker missing"

echo
echo "=== live-served frontend pre-activation checks ==="
live_app_code="$(curl -sS --max-time 8 -o "$LIVE_APP" -w "%{http_code}" "$FRONTEND_BASE/app.js" 2>/tmp/stage9n-live-app.err || printf 'curl_failed')"
live_stub_code="$(curl -sS --max-time 8 -o "$LIVE_STUB" -w "%{http_code}" "$FRONTEND_BASE/router_shadow_read_stub.js" 2>/tmp/stage9n-live-stub.err || printf 'curl_failed')"

echo "live_app_code=$live_app_code"
echo "live_stub_code=$live_stub_code"

if [ "$live_app_code" = "200" ]; then
  pass "live-served app.js fetched with HTTP 200"

  grep -q "EdgeRouterShadowReadSurface" "$LIVE_APP" 2>/dev/null \
    && pass "live-served app.js contains EdgeRouterShadowReadSurface" \
    || check_fail "live-served app.js missing EdgeRouterShadowReadSurface"

  grep -q "EdgeRouterShadowReadOperatorGate" "$LIVE_APP" 2>/dev/null \
    && pass "live-served app.js contains EdgeRouterShadowReadOperatorGate" \
    || check_fail "live-served app.js missing EdgeRouterShadowReadOperatorGate"

  grep -q "OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false" "$LIVE_APP" 2>/dev/null \
    && pass "live-served operator gate default false marker exists" \
    || check_fail "live-served operator gate default false marker missing"

  grep -q "operator_browser_shadow_read_activation_disabled" "$LIVE_APP" 2>/dev/null \
    && pass "live-served operator gate disabled reason exists" \
    || check_fail "live-served operator gate disabled reason missing"

  if grep -q "/api/router/dry-run" "$LIVE_APP" 2>/dev/null; then
    check_fail "live-served app.js contains /api/router/dry-run"
    grep -n "/api/router/dry-run" "$LIVE_APP" | sed -n '1,80p'
  else
    pass "live-served app.js contains no /api/router/dry-run"
  fi
else
  check_fail "could not fetch live-served app.js"
fi

if [ "$live_stub_code" = "200" ]; then
  pass "live-served router_shadow_read_stub.js fetched with HTTP 200"
  grep -q 'const ROUTER_DRY_RUN_ENDPOINT = "/api/router/dry-run";' "$LIVE_STUB" 2>/dev/null \
    && pass "live-served stub contains backend dry-run endpoint boundary" \
    || check_fail "live-served stub missing endpoint boundary"

  grep -q "const ROUTER_SHADOW_READ_ENABLED = false;" "$LIVE_STUB" 2>/dev/null \
    && pass "live-served ROUTER_SHADOW_READ_ENABLED remains false" \
    || check_fail "live-served ROUTER_SHADOW_READ_ENABLED=false marker missing"

  grep -q "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;" "$LIVE_STUB" 2>/dev/null \
    && pass "live-served ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT remains false" \
    || check_fail "live-served ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT=false marker missing"
else
  check_fail "could not fetch live-served router shadow-read stub"
fi

echo
echo "=== extract live-served Stage 9D and Stage 9K blocks ==="
python3 - "$LIVE_APP" "$LIVE_BLOCKS" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
out = Path(sys.argv[2])

stage9d_start = "// Stage 9D disabled narrow browser-surface router shadow-read wiring."
stage9d_end = "// End Stage 9D disabled narrow browser-surface router shadow-read wiring."
stage9k_start = "// Stage 9K disabled operator-gated browser shadow-read activation boundary."
stage9k_end = "// End Stage 9K disabled operator-gated browser shadow-read activation boundary."

for marker in (stage9d_start, stage9d_end, stage9k_start, stage9k_end):
    if marker not in source:
        raise SystemExit(f"missing marker in live app.js: {marker}")

stage9d = source.split(stage9d_start, 1)[1].split(stage9d_end, 1)[0]
stage9k = source.split(stage9k_start, 1)[1].split(stage9k_end, 1)[0]

out.write_text(
    stage9d_start + stage9d + stage9d_end + "\n\n" +
    stage9k_start + stage9k + stage9k_end + "\n",
    encoding="utf-8"
)
print(f"wrote live blocks: {out}")
PY
if [ "$?" = "0" ]; then
  pass "live-served Stage 9D and Stage 9K blocks extracted"
else
  check_fail "could not extract live-served Stage 9D/9K blocks"
fi

echo
echo "=== pre-activation live backend checks ==="
health_before="$(wait_for_health before || true)"
STAGE9N_HEALTH_BEFORE="$health_before"
export STAGE9N_HEALTH_BEFORE
echo "health_before=$health_before"
[ "$health_before" = "200" ] && pass "health before activation is HTTP 200" || check_fail "health before activation is not HTTP 200"

post_before="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"text":"stage9n pre activation check","source":"stage9n","surface":"backend-only"}' \
  -o /tmp/stage9n-router-post-before.out \
  -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage9n-router-post-before.err || printf 'curl_failed')"
STAGE9N_POST_BEFORE="$post_before"
export STAGE9N_POST_BEFORE
echo "post_before=$post_before"
[ "$post_before" = "404" ] && pass "POST /api/router/dry-run is disabled before activation" || check_fail "POST /api/router/dry-run not disabled before activation"

controller_env_before="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
if printf '%s\n' "$controller_env_before" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  check_fail "backend dry-run env already enabled before activation"
else
  pass "backend dry-run env absent before activation"
fi

if queue_clean_check before; then
  STAGE9N_QUEUE_BEFORE_CLEAN="true"
  export STAGE9N_QUEUE_BEFORE_CLEAN
  pass "queue clean before activation"
else
  STAGE9N_QUEUE_BEFORE_CLEAN="false"
  export STAGE9N_QUEUE_BEFORE_CLEAN
  check_fail "queue not clean before activation"
fi

if [ "$fail" != "0" ]; then
  echo "CHECK: pre-activation checks failed, refusing to activate"
else
  echo
  echo "=== activate backend dry-run using temporary systemd drop-in ==="
  sudo mkdir -p "$DROPIN_DIR" || fail=1
  cat <<'EOF' | sudo tee "$DROPIN" >/dev/null
[Service]
Environment=EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1
EOF
  sudo systemctl daemon-reload || fail=1
  sudo systemctl restart edge-queue-controller || fail=1
  rollback_needed=1

  health_enabled="$(wait_for_health enabled || true)"
  STAGE9N_HEALTH_ENABLED="$health_enabled"
  export STAGE9N_HEALTH_ENABLED
  echo "health_enabled=$health_enabled"
  [ "$health_enabled" = "200" ] && pass "health after activation is HTTP 200" || check_fail "health after activation is not HTTP 200"

  controller_env_enabled="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
  if printf '%s\n' "$controller_env_enabled" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
    pass "backend dry-run env present during controlled activation"
  else
    check_fail "backend dry-run env missing during controlled activation"
  fi

  post_enabled="$(curl -sS --max-time 8 -X POST \
    -H 'Content-Type: application/json' \
    -d '{"text":"stage9n backend enabled check","source":"stage9n","surface":"backend-only"}' \
    -o /tmp/stage9n-router-post-enabled.out \
    -w "%{http_code}" \
    "$BASE/api/router/dry-run" 2>/tmp/stage9n-router-post-enabled.err || printf 'curl_failed')"
  STAGE9N_POST_ENABLED="$post_enabled"
  export STAGE9N_POST_ENABLED
  echo "post_enabled=$post_enabled"
  [ "$post_enabled" = "200" ] && pass "POST /api/router/dry-run enabled during activation" || check_fail "POST /api/router/dry-run did not return HTTP 200 during activation"

  echo
  echo "=== exactly one controlled operator-gated browser request through live-served bridge ==="
  if command -v node >/dev/null 2>&1 && [ -f "$LIVE_STUB" ] && [ -f "$LIVE_BLOCKS" ]; then
    STAGE9N_BACKEND_URL="$BASE/api/router/dry-run" \
    STAGE9N_RESULT_FILE="$OPERATOR_GATE_RESULT" \
    node <<'NODE'
const fs = require("fs");
const vm = require("vm");

const stub = fs.readFileSync("/tmp/stage9n-live-router-shadow-read-stub.js", "utf8");
const appBlocks = fs.readFileSync("/tmp/stage9n-live-app-blocks.js", "utf8");
const backendUrl = process.env.STAGE9N_BACKEND_URL;
const resultFile = process.env.STAGE9N_RESULT_FILE;

let fetchCalls = 0;
let observedBody = null;

const sandbox = {
  console,
  window: {},
  document: {
    addEventListener: () => {},
    removeEventListener: () => {},
    querySelector: () => null,
    querySelectorAll: () => []
  },
  navigator: { userAgent: "stage9n-controlled-operator-gate" },
  location: { href: "http://127.0.0.1:8787/stage9n-controlled-operator-gate" },
  localStorage: {
    getItem: () => null,
    setItem: () => {},
    removeItem: () => {}
  },
  fetch: async (url, options) => {
    fetchCalls += 1;
    if (fetchCalls > 1) {
      throw new Error("more than one operator-gated fetch attempted");
    }

    const target = String(url);
    if (target !== "/api/router/dry-run") {
      throw new Error("unexpected operator-gated endpoint: " + target);
    }

    const body = options && options.body ? String(options.body) : "";
    const parsed = body ? JSON.parse(body) : {};
    observedBody = parsed;

    if (parsed.surface !== "manual-diagnostic") {
      throw new Error("unexpected browser-surface value: " + parsed.surface);
    }
    if (parsed.dry_run !== true) {
      throw new Error("operator-gated request did not set dry_run=true");
    }
    if (parsed.dispatch_requested !== false || parsed.dispatch_performed !== false) {
      throw new Error("operator-gated request was not explicitly non-dispatching");
    }

    return fetch(backendUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body
    });
  },
  setTimeout,
  clearTimeout
};

vm.createContext(sandbox);
vm.runInContext(stub, sandbox, { filename: "stage9n-live-router-shadow-read-stub.js" });
vm.runInContext(appBlocks, sandbox, { filename: "stage9n-live-app-blocks.js" });

const shadow = sandbox.window.EdgeRouterShadowRead;
const surface = sandbox.window.EdgeRouterShadowReadSurface;
const gate = sandbox.window.EdgeRouterShadowReadOperatorGate;

if (!shadow) throw new Error("EdgeRouterShadowRead namespace missing");
if (!surface) throw new Error("EdgeRouterShadowReadSurface namespace missing");
if (!gate) throw new Error("EdgeRouterShadowReadOperatorGate namespace missing");

if (shadow.ROUTER_SHADOW_READ_ENABLED !== false) {
  throw new Error("live-served stub flag should start false");
}
if (shadow.ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT !== false) {
  throw new Error("live-served feature flag default should start false");
}
if (gate.OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED !== false) {
  throw new Error("operator gate should start false");
}

shadow.ROUTER_SHADOW_READ_ENABLED = true;
shadow.ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = true;
gate.OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = true;

const operatorGateEnabledInVm =
  gate.OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED === true;

Promise.resolve(
  surface.requestBrowserSurfaceRouterShadowRead("manual-diagnostic", {
    text: "stage9n exactly one controlled operator-gated shadow-read",
    source: "stage9n",
    route_hint: "controlled-operator-gate"
  })
).then((result) => {
  shadow.ROUTER_SHADOW_READ_ENABLED = false;
  shadow.ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;
  gate.OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false;

  const operatorGateRestoredFalseInVm =
    gate.OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED === false;

  const body = result && result.body ? result.body : {};
  const output = {
    ok: result ? result.ok === true : false,
    status: result ? result.status : null,
    endpoint: result ? result.endpoint : null,
    requests: fetchCalls,
    observed_surface: observedBody ? observedBody.surface : null,
    observed_dry_run: observedBody ? observedBody.dry_run : null,
    observed_dispatch_requested: observedBody ? observedBody.dispatch_requested : null,
    observed_dispatch_performed: observedBody ? observedBody.dispatch_performed : null,
    dispatch_requested: result ? result.dispatch_requested : null,
    dispatch_performed: result ? result.dispatch_performed : null,
    body_dispatch_performed: body.dispatch_performed,
    body_dispatch_performed_type: typeof body.dispatch_performed,
    body_ok: body.ok,
    body_dry_run: body.dry_run,
    operator_gate_enabled_in_vm: operatorGateEnabledInVm,
    operator_gate_restored_false_in_vm: operatorGateRestoredFalseInVm,
    body_keys: body && typeof body === "object" ? Object.keys(body).sort() : []
  };

  fs.writeFileSync(resultFile, JSON.stringify(output, null, 2) + "\n");
  console.log(JSON.stringify(output, null, 2));

  if (fetchCalls !== 1) {
    throw new Error("expected exactly one operator-gated fetch, got " + fetchCalls);
  }
  if (!output.ok || output.status !== 200) {
    throw new Error("controlled operator-gated shadow-read did not return HTTP 200");
  }
  if (output.operator_gate_enabled_in_vm !== true) {
    throw new Error("operator gate was not enabled inside VM");
  }
  if (output.operator_gate_restored_false_in_vm !== true) {
    throw new Error("operator gate was not restored false inside VM");
  }
  if (output.observed_surface !== "manual-diagnostic") {
    throw new Error("observed surface mismatch");
  }
  if (output.observed_dry_run !== true) {
    throw new Error("observed dry_run was not true");
  }
  if (output.observed_dispatch_requested !== false) {
    throw new Error("observed dispatch_requested was not false");
  }
  if (output.observed_dispatch_performed !== false) {
    throw new Error("observed dispatch_performed was not false");
  }
  if (output.dispatch_performed !== false) {
    throw new Error("wrapper dispatch_performed was not false");
  }
  if (!(body.dispatch_performed === false || body.dispatch_performed === undefined || body.dispatch_performed === null)) {
    throw new Error("body dispatch_performed indicated dispatch");
  }

  console.log("PASS: controlled operator-gated shadow-read sent exactly one non-dispatching request");
}).catch((error) => {
  try {
    shadow.ROUTER_SHADOW_READ_ENABLED = false;
    shadow.ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;
    gate.OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false;
  } catch (_) {}
  console.error("CHECK:", error.message || error);
  process.exit(1);
});
NODE
    operator_node_check=$?
    if [ "$operator_node_check" = "0" ]; then
      pass "controlled operator-gated Node VM check passed"
    else
      check_fail "controlled operator-gated Node VM check failed"
    fi
  else
    check_fail "node or live-served files unavailable for controlled operator-gated request"
  fi

  if [ -f "$OPERATOR_GATE_RESULT" ]; then
    cat "$OPERATOR_GATE_RESULT"

    browser_requests="$(python3 -c 'import json; print(json.load(open("'"$OPERATOR_GATE_RESULT"'")).get("requests"))' 2>/dev/null || echo unknown)"
    browser_status="$(python3 -c 'import json; print(json.load(open("'"$OPERATOR_GATE_RESULT"'")).get("status"))' 2>/dev/null || echo unknown)"
    browser_ok="$(python3 -c 'import json; print(json.load(open("'"$OPERATOR_GATE_RESULT"'")).get("ok"))' 2>/dev/null || echo unknown)"
    browser_surface="$(python3 -c 'import json; print(json.load(open("'"$OPERATOR_GATE_RESULT"'")).get("observed_surface"))' 2>/dev/null || echo unknown)"
    browser_dry_run="$(python3 -c 'import json; print(json.load(open("'"$OPERATOR_GATE_RESULT"'")).get("observed_dry_run"))' 2>/dev/null || echo unknown)"
    dispatch_requested="$(python3 -c 'import json; print(json.load(open("'"$OPERATOR_GATE_RESULT"'")).get("observed_dispatch_requested"))' 2>/dev/null || echo unknown)"
    dispatch_performed="$(python3 -c 'import json; print(json.load(open("'"$OPERATOR_GATE_RESULT"'")).get("observed_dispatch_performed"))' 2>/dev/null || echo unknown)"
    body_dispatch_performed="$(python3 -c 'import json; print(json.load(open("'"$OPERATOR_GATE_RESULT"'")).get("body_dispatch_performed"))' 2>/dev/null || echo unknown)"
    gate_enabled="$(python3 -c 'import json; print(json.load(open("'"$OPERATOR_GATE_RESULT"'")).get("operator_gate_enabled_in_vm"))' 2>/dev/null || echo unknown)"
    gate_restored="$(python3 -c 'import json; print(json.load(open("'"$OPERATOR_GATE_RESULT"'")).get("operator_gate_restored_false_in_vm"))' 2>/dev/null || echo unknown)"

    STAGE9N_BROWSER_REQUESTS="$browser_requests"
    STAGE9N_BROWSER_STATUS="$browser_status"
    STAGE9N_BROWSER_OK="$browser_ok"
    STAGE9N_BROWSER_SURFACE="$browser_surface"
    STAGE9N_BROWSER_DRY_RUN="$browser_dry_run"
    STAGE9N_DISPATCH_REQUESTED="$dispatch_requested"
    STAGE9N_DISPATCH_PERFORMED="$dispatch_performed"
    STAGE9N_BODY_DISPATCH_PERFORMED="$body_dispatch_performed"
    STAGE9N_OPERATOR_GATE_ENABLED_IN_VM="$gate_enabled"
    STAGE9N_OPERATOR_GATE_RESTORED_FALSE_IN_VM="$gate_restored"
    export STAGE9N_BROWSER_REQUESTS STAGE9N_BROWSER_STATUS STAGE9N_BROWSER_OK
    export STAGE9N_BROWSER_SURFACE STAGE9N_BROWSER_DRY_RUN STAGE9N_DISPATCH_REQUESTED
    export STAGE9N_DISPATCH_PERFORMED STAGE9N_BODY_DISPATCH_PERFORMED
    export STAGE9N_OPERATOR_GATE_ENABLED_IN_VM STAGE9N_OPERATOR_GATE_RESTORED_FALSE_IN_VM

    [ "$browser_requests" = "1" ] && pass "exactly one operator-gated request was sent" || check_fail "operator-gated request count was not exactly one"
    [ "$browser_status" = "200" ] && pass "operator-gated shadow-read returned HTTP 200" || check_fail "operator-gated shadow-read did not return HTTP 200"
    case "$browser_ok" in True|true) pass "operator-gated shadow-read ok=true" ;; *) check_fail "operator-gated shadow-read ok was not true" ;; esac
    [ "$browser_surface" = "manual-diagnostic" ] && pass "browser-surface value was manual-diagnostic" || check_fail "browser-surface value mismatch"
    case "$browser_dry_run" in True|true) pass "operator-gated dry_run=true" ;; *) check_fail "operator-gated dry_run was not true" ;; esac
    case "$dispatch_requested" in False|false) pass "operator-gated dispatch_requested=false" ;; *) check_fail "operator-gated dispatch_requested was not false" ;; esac
    case "$dispatch_performed" in False|false) pass "operator-gated dispatch_performed=false" ;; *) check_fail "operator-gated dispatch_performed was not false" ;; esac
    case "$body_dispatch_performed" in False|false|None|null) pass "backend body did not indicate dispatch" ;; *) check_fail "backend body indicates dispatch_performed=$body_dispatch_performed" ;; esac
    case "$gate_enabled" in True|true) pass "operator gate enabled inside Node VM only" ;; *) check_fail "operator gate was not enabled inside Node VM" ;; esac
    case "$gate_restored" in True|true) pass "operator gate restored false inside Node VM" ;; *) check_fail "operator gate was not restored false inside Node VM" ;; esac
  else
    check_fail "operator-gated result file missing"
  fi

  if queue_clean_check enabled; then
    STAGE9N_QUEUE_ENABLED_CLEAN="true"
    export STAGE9N_QUEUE_ENABLED_CLEAN
    pass "queue remained clean after controlled operator-gated request"
  else
    STAGE9N_QUEUE_ENABLED_CLEAN="false"
    export STAGE9N_QUEUE_ENABLED_CLEAN
    check_fail "queue not clean after controlled operator-gated request"
  fi
fi

echo
echo "=== explicit rollback now ==="
rollback_backend

echo
echo "=== post-rollback frontend file safety checks ==="
if grep -q "/api/router/dry-run" "$APP_JS" 2>/dev/null; then
  check_fail "app.js contains /api/router/dry-run after rollback"
else
  pass "app.js still contains no /api/router/dry-run after rollback"
fi

grep -q "EdgeRouterShadowReadSurface" "$APP_JS" 2>/dev/null \
  && pass "app.js still contains EdgeRouterShadowReadSurface after rollback" \
  || check_fail "app.js missing EdgeRouterShadowReadSurface after rollback"

grep -q "EdgeRouterShadowReadOperatorGate" "$APP_JS" 2>/dev/null \
  && pass "app.js still contains EdgeRouterShadowReadOperatorGate after rollback" \
  || check_fail "app.js missing EdgeRouterShadowReadOperatorGate after rollback"

grep -q "OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false" "$APP_JS" 2>/dev/null \
  && pass "repo operator gate default remains false after rollback" \
  || check_fail "repo operator gate default false marker missing after rollback"

grep -q "const ROUTER_SHADOW_READ_ENABLED = false;" "$STUB" 2>/dev/null \
  && pass "repo ROUTER_SHADOW_READ_ENABLED remains false after rollback" \
  || check_fail "repo ROUTER_SHADOW_READ_ENABLED=false missing after rollback"

grep -q "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;" "$STUB" 2>/dev/null \
  && pass "repo ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT remains false after rollback" \
  || check_fail "repo ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT=false missing after rollback"

echo
echo "=== timer and temporary port checks after rollback ==="
power_timer="$(systemctl is-active edge-queue-power-auto-tick.timer 2>/dev/null || true)"
remediation_timer="$(systemctl is-active edge-queue-remediation-tick.timer 2>/dev/null || true)"
legacy_active="$(systemctl is-active edge-queue-scheduler-tick.timer 2>/dev/null || true)"
legacy_enabled="$(systemctl is-enabled edge-queue-scheduler-tick.timer 2>/dev/null || true)"

echo "edge-queue-power-auto-tick.timer active=$power_timer"
echo "edge-queue-remediation-tick.timer active=$remediation_timer"
echo "edge-queue-scheduler-tick.timer active=$legacy_active enabled=$legacy_enabled"

[ "$power_timer" = "active" ] && pass "modern power auto timer is active" || check_fail "modern power auto timer is not active"
[ "$remediation_timer" = "active" ] && pass "modern remediation timer is active" || check_fail "modern remediation timer is not active"

if [ "$legacy_active" = "inactive" ] || [ "$legacy_active" = "unknown" ]; then
  pass "legacy scheduler timer is not active"
else
  check_fail "legacy scheduler timer is unexpectedly active/state=$legacy_active"
fi

if [ "$legacy_enabled" = "disabled" ] || [ "$legacy_enabled" = "masked" ]; then
  pass "legacy scheduler timer is disabled/masked"
else
  check_fail "legacy scheduler timer is not disabled/masked; enabled_state=$legacy_enabled"
fi

if ss -ltnp 2>/dev/null | grep -q ':7076'; then
  check_fail "port 7076 appears to be listening"
  ss -ltnp | grep ':7076' || true
else
  pass "port 7076 is not listening"
fi

echo
echo "=== write Stage 9N evidence ==="
if [ "$fail" = "0" ]; then
  STAGE9N_FINAL_RESULT="pass"
else
  STAGE9N_FINAL_RESULT="fail"
fi
export STAGE9N_FINAL_RESULT
write_evidence

echo
echo "=== Stage 9N smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 9N controlled operator-gated browser shadow-read activation and rollback verified"
else
  echo "FAIL: Stage 9N controlled operator-gated browser shadow-read activation and rollback found issues"
fi

exit "$fail"
