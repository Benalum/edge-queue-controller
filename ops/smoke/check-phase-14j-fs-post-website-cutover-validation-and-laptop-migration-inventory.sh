#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-fs-post-website-cutover-validation-and-laptop-migration-inventory"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

echo "--- phase/result markers ---"
require_fixed "PHASE_14J_FS_POST_WEBSITE_CUTOVER_VALIDATION_AND_LAPTOP_MIGRATION_INVENTORY"
require_fixed "PHASE_14J_FS_RESULT=post_cutover_validation_passed_laptop_migration_inventory_recorded"
require_fixed "NEXT_SAFE_PHASE=phase_14j_ft_read_only_data_container_design_and_data_authority_inspection"

echo "--- website-edge production validation markers ---"
require_fixed "PHASE_14J_FS_STATIC_ROUTE_RESULT=apex_and_www_match_website_edge_loopback_baseline"
require_fixed "alexhartel.com"
require_fixed "www.alexhartel.com"
require_fixed "Root marker: wrapper_like"
require_fixed "Root error marker: absent"
require_fixed "website-edge-test.alexhartel.com"
require_fixed "Diagnostic test hostname can be restored later if desired"

echo "--- asset hash markers ---"
require_fixed "1658e5f03e754ae8fa563a5e7f3655ffbd6a3d368b230080a57c579670da203b"
require_fixed "c1e629398a7bb15ae9735fdb287cc0636cd36504031a93605783a45b12b55d19"
require_fixed "5ea0fc240fbe42ee263e29a730e119b11e29759500dd0764f7ae37adff77765b"

echo "--- laptop inventory markers ---"
require_fixed "cloudflared.service"
require_fixed "docker.service"
require_fixed "edge-queue-controller.service"
require_fixed "edge-wrapper-ui.service"
require_fixed "postgresql@16-main.service"
require_fixed "project-pilot-bridge.service"
require_fixed "edge-queue-power-auto-tick.timer"
require_fixed "edge-queue-power-idle-tick.timer"
require_fixed "edge-queue-remediation-tick.timer"
require_fixed "port 7070"
require_fixed "port 8765"
require_fixed "port 8787"
require_fixed "port 5432"

echo "--- data authority markers ---"
require_fixed "edge_queue.sqlite3"
require_fixed "PostgreSQL 16"
require_fixed "ops/db/backup-laptop-postgres.sh"
require_fixed "Do not move controller/queue until durable state ownership, backup, restore, and rollback are proven"

echo "--- migration map markers ---"
require_fixed "website-edge VM 200"
require_fixed "future data container or VM"
require_fixed "future controller/queue container"
require_fixed "future worker container"
require_fixed "laptop target role"

echo "--- hard-denial markers ---"
require_fixed "no container creation"
require_fixed "no controller/queue migration"
require_fixed "no data migration"
require_fixed "no worker start"
require_fixed "no CT101 call"
require_fixed "no model/Ollama endpoint call"
require_fixed "no production DB/job mutation"
require_fixed "no Phase 14J-AG apply wrapper rerun"

echo "--- doc secret/raw endpoint guard ---"
if grep -Eq 'eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
