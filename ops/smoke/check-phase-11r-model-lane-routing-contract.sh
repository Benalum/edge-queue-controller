#!/usr/bin/env bash
set -u

fail=0

echo "=== Phase 11R smoke: model lane routing contract ==="

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root" || fail=1

echo
echo "=== git baseline ==="
git log --oneline -6
git tag --points-at HEAD

echo
echo "=== python syntax ==="
python3 -m py_compile edge_modules/chat_queue_real_user_creation.py || fail=1

echo
echo "=== source markers ==="
check_marker() {
  label="$1"
  marker="$2"
  file="$3"

  if grep -Fq "$marker" "$file"; then
    echo "PASS: $label"
    grep -nF "$marker" "$file" | sed -n '1,5p'
  else
    echo "FAIL: missing $label"
    echo "marker: $marker"
    echo "file: $file"
    fail=1
  fi
}

check_marker "contract begin marker" "STAGE_5P11R_MODEL_LANE_CONTRACT_BEGIN" edge_modules/chat_queue_real_user_creation.py
check_marker "contract end marker" "STAGE_5P11R_MODEL_LANE_CONTRACT_END" edge_modules/chat_queue_real_user_creation.py
check_marker "routing decision payload" '"routing_decision": routing_decision' edge_modules/chat_queue_real_user_creation.py
check_marker "model tier payload" '"model_tier": routing_decision["model_tier"]' edge_modules/chat_queue_real_user_creation.py
check_marker "queue lane payload" '"queue_lane": routing_decision["queue_lane"]' edge_modules/chat_queue_real_user_creation.py
check_marker "runtime unchanged doc" "change worker concurrency" docs/phase-11r-model-lane-routing-contract.md

echo
echo "=== helper behavior ==="
python3 - <<'PYHELPER' || fail=1
from edge_modules.chat_queue_real_user_creation import stage5p11r_build_model_lane_decision

cases = [
    ("qwen3:0.6b", "chat", "tiny", "model-tiny", 4),
    ("qwen3:1.7b", "chat", "small", "model-small", 2),
    ("gemma3:4b", "chat", "medium", "model-medium", 1),
    ("gemma4:e4b", "companion", "large", "model-large", 1),
]

for model, mode, expected_tier, expected_lane, expected_parallel in cases:
    decision = stage5p11r_build_model_lane_decision(
        requested_model=model,
        mode=mode,
    )
    assert decision["version"] == "stage_5p11r_v1", decision
    assert decision["dispatch_mode"] == "metadata_only", decision
    assert decision["runtime_behavior_changed"] is False, decision
    assert decision["model_tier"] == expected_tier, decision
    assert decision["queue_lane"] == expected_lane, decision
    assert decision["model_lane"] == expected_lane, decision
    assert decision["max_parallel_hint"] == expected_parallel, decision

print("PASS: helper routing decisions match expected model lanes")
PYHELPER

echo
echo "=== no schema migration guard ==="
if grep -RInE 'ALTER TABLE (app_jobs|jobs) ADD COLUMN (model_tier|queue_lane|model_lane|routing_decision)|ADD COLUMN (model_tier|queue_lane|model_lane|routing_decision)' edge_modules edge_controller.py 2>/dev/null; then
  echo "FAIL: lane-related schema migration marker found"
  fail=1
else
  echo "PASS: no lane-related app_jobs/jobs schema migration added"
fi

echo
echo "=== no runtime parallelism change guard ==="
if git diff -- edge_modules/chat_queue_real_user_creation.py docs/phase-11r-model-lane-routing-contract.md ops/smoke/check-phase-11r-model-lane-routing-contract.sh \
  | grep -E 'OLLAMA_NUM_PARALLEL|MAX_JOBS_PER_RUN|WORKER_POLL_SECONDS|claim_next_job|/internal/jobs/claim'; then
  echo "FAIL: runtime parallelism/claim marker changed"
  fail=1
else
  echo "PASS: no runtime parallelism or claim behavior changed"
fi

echo
echo "=== changed files guard ==="
bad_status="$(
  git status --short \
    | grep -vE '^[ M?A]{1,2} edge_modules/chat_queue_real_user_creation\.py$' \
    | grep -vE '^[ M?A]{1,2} docs/phase-11r-model-lane-routing-contract\.md$' \
    | grep -vE '^[ M?A]{1,2} ops/smoke/check-phase-11r-model-lane-routing-contract\.sh$' \
    || true
)"

git status --short

if [ -n "$bad_status" ]; then
  echo
  echo "FAIL: unexpected changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 11R expected files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11R model lane routing contract smoke passed"
else
  echo "FAIL: Phase 11R model lane routing contract smoke failed"
fi

[ "$fail" = "0" ]
