#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-h-r11h-pveso-restricted-model-helper-plan-no-apply.md"
SMOKE="ops/smoke/check-stage-16-e3z-h-r11h-pveso-restricted-model-helper-plan-no-apply.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
require_file() { [ -f "$1" ] || fail "missing file: $1"; }
require_text() { local pattern="$1"; local file="$2"; grep -Fq "$pattern" "$file" || fail "missing required text in $file: $pattern"; }

require_file "$DOC"
require_file "$SMOKE"
bash -n "$SMOKE"

require_text "MUTATION_SCOPE: repo docs/smoke/commit/tag/push only." "$DOC"
require_text "No live infrastructure was changed by this phase." "$DOC"
require_text "job_33_status=queued" "$DOC"
require_text "job_33_attempts=0" "$DOC"
require_text "job_33_result_rows=0" "$DOC"
require_text "E3Z_H_R11F_CT203_PVESO_COMMAND_EXEC_OK=0" "$DOC"
require_text "E3Z_H_R11F_CT203_PVESO_FORCED_COMMAND_SEEN=1" "$DOC"
require_text "E3Z_H_R11G_CT203_TO_PVEW_COMMAND_EXEC_OK=0" "$DOC"
require_text "E3Z_H_R11G_PVEW_TO_PVESO_COMMAND_EXEC_OK=0" "$DOC"
require_text "Do not keep retrying E3Z-H service or timer activation until CT203 has an approved, narrow, command-capable path to PVESO." "$DOC"
require_text "Stage 16 E3Z-H R12 — Install PVESO Restricted Model Helper Path, No Service Start" "$DOC"
require_text "APPROVE_STAGE_16_E3Z_H_R12_INSTALL_PVESO_RESTRICTED_MODEL_HELPER_PATH_NO_SERVICE_START" "$DOC"
require_text "R12 should install and validate only \`--preflight-only\`." "$DOC"
require_text "must not call \`/api/generate\`, \`/api/chat\`, \`/api/embed\`, or any other model execution endpoint" "$DOC"
require_text "Persistent workers remain blocked." "$DOC"
require_text "Scheduler timer activation remains blocked." "$DOC"

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
[ -z "$BAD_PATHS" ] || { echo "$BAD_PATHS" >&2; fail "unexpected changed paths outside R11H doc/smoke"; }

echo "E3Z-H R11H restricted model helper plan smoke passed"
