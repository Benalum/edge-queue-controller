#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-lw-status-ui-polish-read-only-review"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

require() {
  local pattern="$1"
  if ! grep -Fq "$pattern" "$DOC"; then
    echo "FAIL: missing required pattern: $pattern"
    exit 1
  fi
}

test -f "$DOC"

require "Phase 14J-LW"
require "Status/UI Polish Read-Only Review"
require "817b7f6"
require "controller-phase-14j-lv-isolated-restore-drill-design-no-apply-2026-06-18"
require "public_root_http=200"
require "public_status_http=200"
require "overall_state=online"
require "normalized_schema_version=2"
require "node_ids_sorted=ct-203,ct-204,pvew,vm-200"
require "storage_policy=manual-unlock-only"
require "storage_mount_state=unknown"
require "ct204_expected_state=stopped"
require "ct204_data_authority=false"
require "privateStorageInfrastructureGroup"
require "Private backup storage policy:"
require "no frontend deploy"
require "no controller deploy"
require "no service restart/reload/enable/start/stop"
require "no DB restore/import/migration"
require "no storage unlock/mount/format/key/crypttab/fstab mutation"
require "no CT204 start"
require "no PVESO wake/start"
require "no Cloudflare/DNS/tunnel mutation"
require "PASS_PHASE_14J_LW_STATUS_UI_POLISH_READ_ONLY_REVIEW_DONE"

echo "PASS: 14J-LW status/UI polish read-only review guardrails present"
echo "PASS_${PHASE}"
