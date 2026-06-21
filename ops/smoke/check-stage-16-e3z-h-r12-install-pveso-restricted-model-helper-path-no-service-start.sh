#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-h-r12-install-pveso-restricted-model-helper-path-no-service-start.md"
SMOKE="ops/smoke/check-stage-16-e3z-h-r12-install-pveso-restricted-model-helper-path-no-service-start.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
require_file() { [ -f "$1" ] || fail "missing file: $1"; }
require_text() { local pattern="$1"; local file="$2"; grep -Fq "$pattern" "$file" || fail "missing required text in $file: $pattern"; }

require_file "$DOC"
require_file "$SMOKE"
bash -n "$SMOKE"

require_text 'MUTATION_SCOPE: CT203 key/env plus PVESO forced-command helper install and preflight-only validation, then repo docs/smoke/commit/tag/push.' "$DOC"
require_text 'APPROVE_STAGE_16_E3Z_H_R12_INSTALL_PVESO_RESTRICTED_MODEL_HELPER_PATH_NO_SERVICE_START' "$DOC"
require_text 'R12 recovery R5 validated the helper path from CT203 with Python subprocess calls' "$DOC"
require_text '/etc/edge-queue-controller/pveso-restricted-helper/id_ed25519' "$DOC"
require_text '/etc/edge-queue-controller/pveso-restricted-helper.env' "$DOC"
require_text '/usr/local/sbin/apc-e3z-h-model-call-helper' "$DOC"
require_text 'APC_E3Z_H_R12_HELPER_KEY_BEGIN' "$DOC"
require_text 'APC_E3Z_H_R12_HELPER_KEY_END' "$DOC"
require_text 'does not grant broad arbitrary shell access' "$DOC"
require_text 'CT203 to PVESO helper `--preflight-only`: `ok`' "$DOC"
require_text 'CT203 to PVESO arbitrary command rejection: `ok`' "$DOC"
require_text 'R12 did not call Ollama generate/chat/embed/completion endpoints.' "$DOC"
require_text 'service_active=inactive' "$DOC"
require_text 'timer_enabled=disabled' "$DOC"
require_text 'env_delegation=0' "$DOC"
require_text 'job_results_total=12' "$DOC"
require_text 'job_33_status=queued' "$DOC"
require_text 'job_33_attempts=0' "$DOC"
require_text 'job_33_result_rows=0' "$DOC"
require_text 'Stage 16 E3Z-H R13 — Start Service Once, Exact Job 33, Restricted PVESO Helper' "$DOC"
require_text 'Persistent workers remain blocked.' "$DOC"
require_text 'Scheduler timer activation remains blocked' "$DOC"

STATUS_PATHS="$(git status --short --untracked-files=all | sed 's/^...//')"
ALLOWED_PATHS="$(cat <<EOF_ALLOWED
$DOC
$SMOKE
EOF_ALLOWED
)"
BAD_PATHS="$(printf '%s\n' "$STATUS_PATHS" | while IFS= read -r path; do
  [ -z "$path" ] && continue
  printf '%s\n' "$ALLOWED_PATHS" | grep -Fxq "$path" || printf '%s\n' "$path"
done)"
[ -z "$BAD_PATHS" ] || { echo "$BAD_PATHS" >&2; fail "unexpected changed paths outside R12 doc/smoke"; }

echo "E3Z-H R12 restricted PVESO helper path smoke passed"
