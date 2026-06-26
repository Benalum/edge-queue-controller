#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

TARGET="edge_controller.py"
DOC="docs/stage-16-fc-o45-e-cl-h-r1-neutralize-unsafe-last-message-source-branch.md"
SMOKE="ops/smoke/check-stage-16-fc-o45-e-cl-h-r1-neutralize-unsafe-last-message-source-branch.sh"

test -f "$TARGET"
test -f "$DOC"
test -f "$SMOKE"

check_source() {
  local needle="$1"
  grep -Fq "$needle" "$TARGET"
}

check_doc() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

python3 -m py_compile "$TARGET"

check_source "Stage 16 FC-O45-E-CL-H-R1: CL-F-R2 direct last_message branch is intentionally disabled"
check_source "def _stage16_chc_companion_study_action_dispatch"
check_source "payload = await request.json()"
check_source "action = _stage16_chc_companion_study_action_normalize"
check_source "if action in (\"status\", \"study_status\", \"session_status\")"

if grep -Fq "Stage 16 FC-O45-E-CL-F-R2: authenticated deterministic last_message branch after JSON body parse" "$TARGET"; then
  echo "REFUSE_UNSAFE_CL_F_R2_BRANCH_MARKER_PRESENT"
  exit 1
fi

if grep -Fq "return _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp" "$TARGET"; then
  echo "REFUSE_UNSAFE_HELPER_RETURN_STILL_PRESENT"
  exit 1
fi

python3 - <<'PY_VALIDATE'
import ast
from pathlib import Path

text = Path("edge_controller.py").read_text()
lines = text.splitlines()
tree = ast.parse(text)

dispatch = None
for node in ast.walk(tree):
    if isinstance(node, (ast.AsyncFunctionDef, ast.FunctionDef)) and node.name == "_stage16_chc_companion_study_action_dispatch":
        dispatch = node
        break

if dispatch is None:
    raise SystemExit("REFUSE_DISPATCH_NOT_FOUND")

start = dispatch.lineno
end = getattr(dispatch, "end_lineno", start)
body_lines = lines[start - 1:end]

def scoped_line(needle):
    for offset, line in enumerate(body_lines, start):
        if needle in line:
            return offset
    raise SystemExit(f"REFUSE_MISSING_IN_DISPATCH {needle!r}")

payload_line = scoped_line("payload = await request.json()")
action_line = scoped_line("action = _stage16_chc_companion_study_action_normalize")
disabled_line = scoped_line("Stage 16 FC-O45-E-CL-H-R1: CL-F-R2 direct last_message branch is intentionally disabled")
status_line = scoped_line('if action in ("status", "study_status", "session_status")')

print(f"CL_H_R2_SMOKE_DISPATCH_LINE={start}")
print(f"CL_H_R2_SMOKE_DISPATCH_END_LINE={end}")
print(f"CL_H_R2_SMOKE_PAYLOAD_LINE={payload_line}")
print(f"CL_H_R2_SMOKE_ACTION_LINE={action_line}")
print(f"CL_H_R2_SMOKE_DISABLED_LINE={disabled_line}")
print(f"CL_H_R2_SMOKE_STATUS_LINE={status_line}")

assert start < payload_line < action_line < disabled_line < status_line <= end

between = "\n".join(lines[action_line - 1:status_line - 1])
assert "_stage16_fc_o45_e_cl_f_companion_study_last_message_mvp(" not in between
assert "return _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp" not in text
assert "stage16_fc_o45_e_cl_f_last_message_contract" in text

print("CL_H_R2_UNSAFE_BRANCH_REMOVED_VALIDATION_DONE=yes")
PY_VALIDATE

check_doc "Neutralize Unsafe Last-Message Source Branch"
check_doc "CL-G deployment proved the branch returned HTTP 200 without bearer authentication"
check_doc "CL-H-R1 attempted to neutralize"
check_doc "scoping line-order validation"
check_doc "CL-G-R3 verified"
check_doc "unauthenticated last_message => HTTP 400 unsupported_companion_study_action"
check_doc "unauthenticated supported status action => HTTP 401 Missing bearer token"
check_doc "1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2"
check_doc "ce49016c13871cac8968eee9567ba4db4f2e3f96b017519731640ebcf887f1a5"
check_doc "jobs_total=576"
check_doc "results_total=83"
check_doc "queued_companion=0"
check_doc "cleanup_rows=440"
check_doc "unsafe direct response branch is absent from source"
check_doc "not called from the Study action dispatcher after CL-H-R2"
check_doc "Do not deploy the CL-F-R2 source"
check_doc "source-only auth pinpoint"

changed_paths="$(git status --porcelain | awk '{print $2}')"
echo "$changed_paths"

for required in "$TARGET" "$DOC" "$SMOKE"; do
  grep -Fxq "$required" <<<"$changed_paths"
done

unexpected="$(
  printf '%s\n' "$changed_paths" |
    grep -v -Fx "$TARGET" |
    grep -v -Fx "$DOC" |
    grep -v -Fx "$SMOKE" || true
)"
if [ -n "$unexpected" ]; then
  echo "REFUSE_UNEXPECTED_CHANGED_PATHS"
  echo "$unexpected"
  exit 1
fi

if grep -E '(^public/|^frontend/|^web/|^static/|^ops/systemd/|^ops/workers/|^ops/db/)' <<<"$changed_paths"; then
  echo "REFUSE_UNEXPECTED_RUNTIME_OR_FRONTEND_CHANGE"
  exit 1
fi

echo "PASS stage-16-fc-o45-e-cl-h-r2 neutralize unsafe last_message source branch smoke"
