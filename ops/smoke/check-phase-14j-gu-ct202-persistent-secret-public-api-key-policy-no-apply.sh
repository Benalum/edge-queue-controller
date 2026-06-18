#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-gu-ct202-persistent-secret-public-api-key-policy-no-apply"
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

require_line 'Phase 14J-GU documents the required CT202 persistent secret and public API key policy'
require_line 'This phase does **not** create, print, store, rotate, validate, or install any secret value.'
require_line 'This phase does **not** modify CT202, systemd, Cloudflare, public routes, laptop controller, or any database.'

require_line 'laptop controller remains the live controller/queue authority'
require_line 'laptop-local `edge_queue.sqlite3` remains the live primary controller platform data authority'
require_line 'CT202 remains a private controller candidate only'
require_line 'CT202 is not authoritative'
require_line 'CT202 service remains disabled/inactive'
require_line 'CT202 onboot/autostart remains off'

require_line 'private CT202 auth-flow smokes used temporary in-process public API key behavior only'
require_line 'CT202 systemd unit intentionally contains no persistent public API key, token, password, secret, bearer, or auth URL'
require_line 'Secret material must never be:'
require_line 'printed in terminal output'
require_line 'pasted into ChatGPT'
require_line 'written into `APC_LAST_OUTPUT`'
require_line 'committed to git'
require_line 'stored in Source files'
require_line 'embedded directly in a systemd unit file'

require_line 'A future apply phase should use a root-owned environment file or equivalent secure delivery mechanism.'
require_line 'secret file should be owned by root'
require_line 'secret file mode should be `0600`'
require_line 'No file is created by Phase 14J-GU.'

require_line 'do not commit the key'
require_line 'do not place the key in Source files'
require_line 'do not place the key in ChatGPT'
require_line 'do not write the key to `APC_LAST_OUTPUT`'
require_line 'do not print the key during generation or validation'
require_line 'do not store the key in the systemd unit body'

require_line 'The exact future path and variable names must be approved before an apply phase.'
require_line 'Future validation checklist'
require_line 'Future rotation checklist'
require_line 'Rejected designs'
require_line 'Secret policy must exist before:'
require_line 'CT202 persistent runtime rehearsal'
require_line 'CT202 public route cutover'
require_line 'CT202 authority cutover'

require_line 'Next safe phase: Phase 14J-GV - CT202 temporary runtime rehearsal plan, no enable, no apply.'

require_line 'no CT202 authority cutover'
require_line 'no CT202 data migration/import'
require_line 'no laptop DB export/import'
require_line 'no SQLite copy'
require_line 'no secret generation'
require_line 'no secret printing'
require_line 'no secret file creation'
require_line 'no environment file creation'
require_line 'no systemd unit mutation'
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

require_line 'No secret was created, printed, stored, committed, or installed by this phase.'

require_absent 'APPROVE_SECRET_APPLY'
require_absent 'APPROVE_RUNTIME_APPLY'
require_absent 'APPROVE_CUTOVER_APPLY'
require_absent 'APPROVE_DATA_MIGRATION'
require_absent 'PUBLIC_API_KEY='
require_absent 'API_KEY='
require_absent 'TOKEN='
require_absent 'PASSWORD='
require_absent 'SECRET='
require_absent 'Bearer '
require_absent 'systemctl enable edge-queue-controller.service'
require_absent 'pct set 202 -onboot 1'
require_absent 'cloudflare tunnel route'
require_absent 'ollama serve'

echo "PASS: ${PHASE}"
