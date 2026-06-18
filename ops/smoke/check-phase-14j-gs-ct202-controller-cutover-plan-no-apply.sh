#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-gs-ct202-controller-cutover-plan-no-apply"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"

require_line() {
  local pattern="$1"
  echo "CHECK: $pattern"
  grep -F "$pattern" "$DOC" >/dev/null
  echo "PASS: $pattern"
}

require_absent() {
  local pattern="$1"
  echo "CHECK_ABSENT: $pattern"
  if grep -F "$pattern" "$DOC" >/dev/null; then
    echo "FAIL: forbidden literal present: $pattern" >&2
    exit 1
  fi
  echo "PASS_ABSENT: $pattern"
}

require_line 'Phase 14J-GS records the controller cutover plan boundaries'
require_line 'This phase does **not** execute cutover.'
require_line 'repo HEAD, origin/main, Phase 14J-GR tag, and clean state were verified'
require_line 'laptop-local `edge_queue.sqlite3` quick_check returned `ok`'
require_line 'Tailscale SSH path to Proxmox with `pct` access was usable'
require_line 'CT202 was running for inspection only'
require_line 'CT202 onboot/autostart was `0`'
require_line 'CT202 `edge-queue-controller.service` was loaded, disabled, and inactive'
require_line 'CT202 had no guarded-port controller listeners on `7070`, `17070`, `17071`, or `17072`'
require_line 'CT202 SQLite quick_check returned `ok`'
require_line 'CT202 application table count was `25`'
require_line 'CT202 `jobs`, `workers`, `user_sessions`, and `router_logs` row counts were `0`'

require_line 'laptop controller remains the live controller/queue authority'
require_line 'laptop-local `edge_queue.sqlite3` remains the live primary controller platform data authority'
require_line 'CT202 remains a private controller candidate only'
require_line 'CT202 is not authoritative'

require_line 'Data authority decision'
require_line 'fresh-start CT202 authority cutover'
require_line 'selective import from laptop DB to CT202 DB'
require_line 'full migration from laptop DB to CT202 DB'

require_line 'Persistent secret/public API key policy'
require_line 'Runtime activation/autostart policy'
require_line 'Public route cutover and rollback plan'
require_line 'Laptop controller fallback plan'
require_line 'Worker/model runtime remains out of scope'

require_line 'no CT202 authority cutover'
require_line 'no CT202 data migration/import'
require_line 'no `systemctl start`'
require_line 'no `systemctl enable`'
require_line 'no `systemctl daemon-reload`'
require_line 'no CT202 onboot/autostart mutation'
require_line 'no persistent controller runtime activation'
require_line 'no public route mutation'
require_line 'no Cloudflare mutation'
require_line 'no laptop controller stop'
require_line 'no live laptop DB mutation'
require_line 'no CT101 call'
require_line 'no model/Ollama endpoint call'
require_line 'no worker start'
require_line 'no production DB/job mutation'
require_line 'no rerun of the Phase 14J-AG apply wrapper'
require_line 'no destructive GitHub branch/repository deletion'

require_line 'Next safe phase: Phase 14J-GT - CT202 cutover design options, no apply.'

require_absent 'APPROVE_CUTOVER_APPLY'
require_absent 'systemctl enable edge-queue-controller.service'
require_absent 'pct set 202 -onboot 1'
require_absent 'cloudflare tunnel route'
require_absent 'ollama serve'

echo "PASS: ${PHASE}"
