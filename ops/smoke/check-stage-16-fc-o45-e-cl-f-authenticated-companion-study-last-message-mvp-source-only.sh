#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

TARGET="edge_controller.py"
DOC="docs/stage-16-fc-o45-e-cl-f-authenticated-companion-study-last-message-mvp-source-only.md"
SMOKE="ops/smoke/check-stage-16-fc-o45-e-cl-f-authenticated-companion-study-last-message-mvp-source-only.sh"

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

check_source "stage16_fc_o45_e_cl_f_last_message_contract"
check_source "def _stage16_fc_o45_e_cl_f_study_last_message_text"
check_source "def _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp"
check_source "def _stage16_chc_companion_study_action_dispatch"
check_source "Stage 16 FC-O45-E-CL-F-R2: authenticated deterministic last_message branch after JSON body parse"
check_source "last_message"
check_source "last_message_mvp"
check_source "study_last_message"
check_source '"/api/companion/study/action"'
check_source "companion_study"
check_source "deterministic_no_model"
check_source "backend-deterministic/no-model"
check_source "stage16_fc_o45_e_cl_f_direct_deterministic_response"
check_source '"authenticated": True'
check_source '"job_id": None'
check_source '"no_model_call": True'
check_source '"no_ollama_call": True'
check_source '"no_pveso_call": True'
check_source '"no_job_insert": True'
check_source '"no_result_insert": True'
check_source '"no_scheduler_activation": True'
check_source '"no_timer_activation": True'
check_source '"no_persistent_worker_activation": True'

if grep -Fq "Stage 16 FC-O45-E-CL-F: stable authenticated Study Companion" "$TARGET"; then
  echo "REFUSE_OLD_PREMATURE_CL_F_BRANCH_MARKER_PRESENT"
  exit 1
fi

python3 - <<'PY_VALIDATE'
import ast
from pathlib import Path

target = Path("edge_controller.py")
source = target.read_text()
lines = source.splitlines()

def first_line_containing(needle, start=1):
    for idx in range(start - 1, len(lines)):
        if needle in lines[idx]:
            return idx + 1
    raise SystemExit(f"REFUSE_MISSING_NEEDLE {needle!r}")

dispatch_line = first_line_containing("async def _stage16_chc_companion_study_action_dispatch")
payload_line = first_line_containing("payload = await request.json()", dispatch_line)
action_line = first_line_containing("action = _stage16_chc_companion_study_action_normalize", payload_line)
branch_line = first_line_containing("Stage 16 FC-O45-E-CL-F-R2: authenticated deterministic last_message branch after JSON body parse", action_line)

print(f"CL_F_R2_SMOKE_DISPATCH_LINE={dispatch_line}")
print(f"CL_F_R2_SMOKE_PAYLOAD_LINE={payload_line}")
print(f"CL_F_R2_SMOKE_ACTION_LINE={action_line}")
print(f"CL_F_R2_SMOKE_BRANCH_LINE={branch_line}")

assert dispatch_line < payload_line < action_line < branch_line

premature_region = "\n".join(lines[dispatch_line - 1:payload_line - 1])
assert "Stage 16 FC-O45-E-CL-F-R2" not in premature_region
assert "Stage 16 FC-O45-E-CL-F: stable authenticated Study Companion" not in source

tree = ast.parse(source)
wanted = {
    "_stage16_fc_o45_e_cl_f_study_last_message_text",
    "_stage16_fc_o45_e_cl_f_companion_study_last_message_mvp",
}
nodes = [
    node for node in tree.body
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name in wanted
]
assert len(nodes) == len(wanted)

module = ast.Module(body=nodes, type_ignores=[])
ast.fix_missing_locations(module)
namespace = {}
exec(compile(module, "cl_f_r2_helper_unit", "exec"), namespace)

result = namespace["_stage16_fc_o45_e_cl_f_companion_study_last_message_mvp"](
    {"action": "last_message", "input_text": "Explain DNS records"},
    user_id="unit-user",
)

print("CL_F_R2_SMOKE_HELPER_OK=" + str(result.get("ok")))
print("CL_F_R2_SMOKE_HELPER_ACTION=" + str(result.get("action")))
print("CL_F_R2_SMOKE_HELPER_MODE=" + str(result.get("mode")))
print("CL_F_R2_SMOKE_HELPER_MODEL=" + str(result.get("model")))
print("CL_F_R2_SMOKE_HELPER_JOB_ID=" + str(result.get("job_id")))
print("CL_F_R2_SMOKE_HELPER_MESSAGE=" + str(result.get("response", {}).get("message")))

assert result["ok"] is True
assert result["feature"] == "stage16_fc_o45_e_cl_f_last_message_contract"
assert result["surface"] == "companion_study"
assert result["action"] == "last_message"
assert result["authenticated"] is True
assert result["mode"] == "deterministic_no_model"
assert result["model"] == "backend-deterministic/no-model"
assert result["source"] == "stage16_fc_o45_e_cl_f_direct_deterministic_response"
assert result["job_id"] is None
assert result["user_id"] == "unit-user"
assert "Explain DNS records" in result["response"]["message"]

guardrails = result["guardrails"]
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
    assert guardrails[key] is True, key

print("CL_F_R2_HELPER_UNIT_VALIDATION_DONE=yes")
PY_VALIDATE

check_doc "Authenticated Companion/Study Last-Message MVP Source-Only Patch"
check_doc "HEAD/origin/main=1f2c811"
check_doc "queued_companion=0"
check_doc "cleanup_rows=440"
check_doc "cleanup_tool_candidate_count=0"
check_doc "CK-Y job581 completed exact marker"
check_doc "HTTP 401 Missing bearer token"
check_doc "after JSON body parsing and action normalization"
check_doc "/api/companion/study/action"
check_doc "avoids adding new public unauthenticated behavior"
check_doc "stage16_fc_o45_e_cl_f_last_message_contract"
check_doc "deterministic_no_model"
check_doc "backend-deterministic/no-model"
check_doc "job_id=None"
check_doc "CL-G deploy backend source to CT203"
check_doc "CL-H run authenticated controlled proof"

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

echo "PASS stage-16-fc-o45-e-cl-f-r2 authenticated companion study last-message MVP source smoke"
