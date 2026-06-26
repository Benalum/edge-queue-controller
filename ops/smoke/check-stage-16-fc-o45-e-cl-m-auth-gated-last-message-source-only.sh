#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

TARGET="edge_controller.py"
DOC="docs/stage-16-fc-o45-e-cl-m-auth-gated-last-message-source-only.md"
SMOKE="ops/smoke/check-stage-16-fc-o45-e-cl-m-auth-gated-last-message-source-only.sh"

test -f "$TARGET"
test -f "$DOC"
test -f "$SMOKE"

python3 -m py_compile "$TARGET"

grep -Fq "def _auth_current_user_from_request(request: Request):" "$TARGET"
grep -Fq "def _study_current_user_id(request: Request) -> int:" "$TARGET"
grep -Fq "Missing bearer token." "$TARGET"
grep -Fq "def _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp" "$TARGET"
grep -Fq "Stage 16 FC-O45-E-CL-M: auth-gated deterministic last_message branch" "$TARGET"
grep -Fq "_stage16_cl_m_user_id = _study_current_user_id(request)" "$TARGET"
grep -Fq "return _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp" "$TARGET"

if grep -Fq "Stage 16 FC-O45-E-CL-F-R2: authenticated deterministic last_message branch after JSON body parse" "$TARGET"; then
  echo "REFUSE_UNSAFE_CL_F_R2_BRANCH_PRESENT"
  exit 1
fi

if grep -Fq "Stage 16 FC-O45-E-CL-H-R1: CL-F-R2 direct last_message branch is intentionally disabled" "$TARGET"; then
  echo "REFUSE_DISABLED_MARKER_STILL_PRESENT"
  exit 1
fi

python3 - <<'PY_VALIDATE'
import ast
from pathlib import Path

source = Path("edge_controller.py").read_text()
lines = source.splitlines()
tree = ast.parse(source)

dispatch = None
for node in ast.walk(tree):
    if isinstance(node, ast.AsyncFunctionDef) and node.name == "_stage16_chc_companion_study_action_dispatch":
        dispatch = node
        break

if dispatch is None:
    raise SystemExit("REFUSE_DISPATCH_NOT_FOUND")

start = dispatch.lineno
end = dispatch.end_lineno
body = lines[start - 1:end]

def scoped_line(needle):
    for offset, line in enumerate(body, start):
        if needle in line:
            return offset
    raise SystemExit(f"REFUSE_MISSING_IN_DISPATCH {needle!r}")

payload_line = scoped_line("payload = await request.json()")
action_line = scoped_line("action = _stage16_chc_companion_study_action_normalize")
branch_line = scoped_line("Stage 16 FC-O45-E-CL-M: auth-gated deterministic last_message branch")
if_line = scoped_line('if action in ("last_message", "last_message_mvp", "study_last_message"):')
auth_line = scoped_line("_stage16_cl_m_user_id = _study_current_user_id(request)")
return_line = scoped_line("return _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp")
status_line = scoped_line('if action in ("status", "study_status", "session_status")')

print(f"CL_M_SMOKE_DISPATCH_LINE={start}")
print(f"CL_M_SMOKE_DISPATCH_END_LINE={end}")
print(f"CL_M_SMOKE_PAYLOAD_LINE={payload_line}")
print(f"CL_M_SMOKE_ACTION_LINE={action_line}")
print(f"CL_M_SMOKE_BRANCH_LINE={branch_line}")
print(f"CL_M_SMOKE_IF_LINE={if_line}")
print(f"CL_M_SMOKE_AUTH_LINE={auth_line}")
print(f"CL_M_SMOKE_RETURN_LINE={return_line}")
print(f"CL_M_SMOKE_STATUS_LINE={status_line}")

assert start < payload_line < action_line < branch_line < if_line < auth_line < return_line < status_line <= end

branch_segment = "\n".join(lines[if_line - 1:status_line - 1])
assert "_study_current_user_id(request)" in branch_segment
assert "_stage16_fc_o45_e_cl_f_companion_study_last_message_mvp" in branch_segment
assert branch_segment.find("_study_current_user_id(request)") < branch_segment.find("_stage16_fc_o45_e_cl_f_companion_study_last_message_mvp")

assert source.count("Stage 16 FC-O45-E-CL-M: auth-gated deterministic last_message branch") == 1
assert source.count("_stage16_cl_m_user_id = _study_current_user_id(request)") == 1
assert source.count("return _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp") == 1
assert "Stage 16 FC-O45-E-CL-F-R2: authenticated deterministic last_message branch after JSON body parse" not in source
assert "Stage 16 FC-O45-E-CL-H-R1: CL-F-R2 direct last_message branch is intentionally disabled" not in source

print("CL_M_AUTH_BEFORE_RETURN_STATIC_VALIDATION_DONE=yes")
PY_VALIDATE

python3 - <<'PY_HELPER'
import ast
from pathlib import Path

source = Path("edge_controller.py").read_text()
tree = ast.parse(source)

names = {
    "_stage16_fc_o45_e_cl_f_study_last_message_text",
    "_stage16_fc_o45_e_cl_f_companion_study_last_message_mvp",
}
nodes = [
    node for node in tree.body
    if isinstance(node, ast.FunctionDef) and node.name in names
]

if len(nodes) != len(names):
    raise SystemExit("REFUSE_HELPER_NODES_NOT_FOUND")

module = ast.Module(body=nodes, type_ignores=[])
ast.fix_missing_locations(module)
namespace = {}
exec(compile(module, "cl_m_helper_unit", "exec"), namespace)

result = namespace["_stage16_fc_o45_e_cl_f_companion_study_last_message_mvp"](
    {"action": "last_message", "input_text": "Explain secure DNS"},
    user_id=123,
)

print(f"CL_M_HELPER_OK={result.get('ok')}")
print(f"CL_M_HELPER_ACTION={result.get('action')}")
print(f"CL_M_HELPER_MODE={result.get('mode')}")
print(f"CL_M_HELPER_MODEL={result.get('model')}")
print(f"CL_M_HELPER_JOB_ID={result.get('job_id')}")
print(f"CL_M_HELPER_USER_ID={result.get('user_id')}")

assert result["ok"] is True
assert result["feature"] == "stage16_fc_o45_e_cl_f_last_message_contract"
assert result["action"] == "last_message"
assert result["authenticated"] is True
assert result["mode"] == "deterministic_no_model"
assert result["model"] == "backend-deterministic/no-model"
assert result["job_id"] is None
assert result["user_id"] == 123

for key in [
    "no_model_call",
    "no_ollama_call",
    "no_pveso_call",
    "no_job_insert",
    "no_result_insert",
    "no_scheduler_activation",
    "no_timer_activation",
    "no_persistent_worker_activation",
]:
    assert result["guardrails"][key] is True, key

print("CL_M_HELPER_UNIT_VALIDATION_DONE=yes")
PY_HELPER

check_doc() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

check_doc "Auth-Gated Last-Message Source-Only Reimplementation"
check_doc "8e612dd"
check_doc "29f1cc92f9c6c7a6c1c89b8b8454c2d0118a820b0d9df58dc6cc947bc3c4d857"
check_doc "user_id = _study_current_user_id(request)"
check_doc "HTTPException(status_code=401, detail=\"Missing bearer token.\")"
check_doc "Stage 16 FC-O45-E-CL-M: auth-gated deterministic last_message branch"
check_doc "feature=stage16_fc_o45_e_cl_f_last_message_contract"
check_doc "mode=deterministic_no_model"
check_doc "model=backend-deterministic/no-model"
check_doc "job_id=None"
check_doc "unauthenticated action=last_message returns HTTP 401 Missing bearer token"
check_doc "authenticated action=last_message returns HTTP 200"
check_doc "no model/Ollama/PVESO call"
check_doc "CL-N should deploy this source to CT203"

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

echo "PASS stage-16-fc-o45-e-cl-m auth-gated last_message source-only smoke"
