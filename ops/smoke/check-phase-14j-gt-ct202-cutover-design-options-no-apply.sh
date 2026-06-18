#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-gt-ct202-cutover-design-options-no-apply"
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

require_line 'Phase 14J-GT documents the available data-authority design options'
require_line 'This phase does **not** select, approve, or execute a cutover.'

require_line 'laptop controller remains the live controller/queue authority'
require_line 'laptop-local `edge_queue.sqlite3` remains the live primary controller platform data authority'
require_line 'CT202 remains a private controller candidate only'
require_line 'CT202 is not authoritative'
require_line 'CT202 service remains disabled/inactive'
require_line 'CT202 onboot/autostart remains off'

require_line 'Design option A - Fresh-start CT202 authority cutover'
require_line 'Design option B - Selective import from laptop DB to CT202 DB'
require_line 'Design option C - Full migration from laptop DB to CT202 DB'

require_line 'Fresh-start is the safest first authority model'
require_line 'Selective import is likely the best eventual production path'
require_line 'Full migration should be treated as highest-risk'

require_line 'Prefer **selective import** if durable user/account/credit state must survive CT202 authority cutover.'
require_line 'Prefer **fresh-start** if CT202 can safely begin with empty volatile controller state'
require_line 'Avoid **full migration** unless complete state continuity is mandatory'

require_line 'Next safe phase: Phase 14J-GU - CT202 persistent secret/public API key policy, no apply.'

require_line 'no CT202 authority cutover'
require_line 'no CT202 data migration/import'
require_line 'no laptop DB export/import'
require_line 'no SQLite copy'
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

require_absent 'APPROVE_CUTOVER_APPLY'
require_absent 'APPROVE_DATA_MIGRATION'
require_absent 'sqlite3 edge_queue.sqlite3 .dump'
require_absent 'systemctl enable edge-queue-controller.service'
require_absent 'pct set 202 -onboot 1'
require_absent 'cloudflare tunnel route'
require_absent 'ollama serve'

echo "PASS: ${PHASE}"
