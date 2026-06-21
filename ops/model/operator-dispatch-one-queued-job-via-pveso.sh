#!/usr/bin/env bash
set -euo pipefail

PHASE="stage-16-e3o-controlled-operator-dispatch-artifact-no-run"
REQUIRED_EXEC_APPROVAL="APPROVE_STAGE_16_E3P_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION"
DEFAULT_RUN_ROOT="${APC_OPERATOR_DISPATCH_RUN_ROOT:-/tmp/apc-operator-dispatch-runs}"

usage() {
  cat <<'EOF_USAGE'
operator-dispatch-one-queued-job-via-pveso.sh

Stage 16 E3O no-run artifact.

Purpose:
  Define the controlled operator dispatch interface for exactly one queued CT203 job ID,
  while keeping scheduler and persistent workers default-off.

Supported safe modes in E3O:
  --help
      Print this help text.

  --contract
      Print the safety contract and future execution requirements.

  --plan-only --job-id N [--expected-model MODEL] [--run-root PATH] [--max-runtime-seconds SECONDS]
      Print a future execution plan. This does not contact CT203, PVESO, Ollama, or any model endpoint.

Execution mode:
  --execute-approved is intentionally disabled in E3O.
  It exits with E3O_NO_RUN_ARTIFACT_EXECUTION_DISABLED even when the approval marker is supplied.

Future E3P approval marker:
  APPROVE_STAGE_16_E3P_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION

Hard boundaries:
  - No scheduler activation.
  - No persistent worker activation.
  - No model endpoint call unless a later execution phase is explicitly approved.
  - No DB mutation unless a later execution phase is explicitly approved.
  - No duplicate job_results rows.
  - No public exposure of PVESO or Ollama.
  - CT101 remains stopped/onboot=0 unless separately approved.
EOF_USAGE
}

print_contract() {
  cat <<EOF_CONTRACT
phase=$PHASE
artifact=ops/model/operator-dispatch-one-queued-job-via-pveso.sh
mode=E3O_NO_RUN_ARTIFACT
required_future_approval=$REQUIRED_EXEC_APPROVAL

controlled_dispatch_contract:
  input:
    - exactly one job_id
    - optional expected_model assertion
    - explicit run_root for durable artifacts
    - explicit max_runtime_seconds
  preflight_must_verify:
    - CT203 DB integrity ok
    - target job exists
    - target job status is queued
    - target job has zero job_results rows
    - target job requested_model is allowlisted
    - scheduler is not active
    - persistent workers are not active
    - EDGE_PERSISTENT_LANE_WORKERS_ENABLED is absent or false
    - PVESO Ollama is active and localhost-only on 127.0.0.1:11434
    - PVESO non-localhost 11434 listener count is zero
    - PVESO runner process count is zero before start
    - CT101 is stopped and onboot=0
  durable_artifacts_must_include:
    - run_dir
    - preflight.json
    - adapter.stdout.txt
    - adapter.stderr.txt
    - model_response.txt or response.json
    - db_preflight.json
    - db_postflight.json
    - recovery_hint.txt
    - final_status.txt
  timeout_recovery_must_classify:
    - DB completed with one result row: do not rerun
    - DB queued with zero result rows and no runner: rerun only with explicit approval
    - DB queued with zero result rows and runner active: do not rerun; classify later
    - DB completed with multiple result rows: duplicate-result failure
  duplicate_result_guard:
    - refuse if job_results count for target job is not zero before execution
    - verify exactly one job_results row after completion
  public_boundary:
    - browser never calls PVESO or Ollama directly
    - public API never exposes raw Ollama endpoint
    - frontend receives completed output only through CT203 DB/API
EOF_CONTRACT
}

die() {
  echo "ERROR: $*" >&2
  exit 2
}

MODE=""
JOB_ID=""
EXPECTED_MODEL=""
RUN_ROOT="$DEFAULT_RUN_ROOT"
MAX_RUNTIME_SECONDS="7200"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --contract)
      print_contract
      exit 0
      ;;
    --plan-only)
      MODE="plan-only"
      shift
      ;;
    --execute-approved)
      MODE="execute-approved"
      shift
      ;;
    --job-id)
      [ "$#" -ge 2 ] || die "--job-id requires a value"
      JOB_ID="$2"
      shift 2
      ;;
    --expected-model)
      [ "$#" -ge 2 ] || die "--expected-model requires a value"
      EXPECTED_MODEL="$2"
      shift 2
      ;;
    --run-root)
      [ "$#" -ge 2 ] || die "--run-root requires a value"
      RUN_ROOT="$2"
      shift 2
      ;;
    --max-runtime-seconds)
      [ "$#" -ge 2 ] || die "--max-runtime-seconds requires a value"
      MAX_RUNTIME_SECONDS="$2"
      shift 2
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

if [ -z "$MODE" ]; then
  usage
  exit 0
fi

case "$JOB_ID" in
  ""|*[!0-9]*)
    die "--job-id must be a positive integer"
    ;;
esac

if [ "$JOB_ID" -le 0 ]; then
  die "--job-id must be greater than zero"
fi

case "$MAX_RUNTIME_SECONDS" in
  ""|*[!0-9]*)
    die "--max-runtime-seconds must be a positive integer"
    ;;
esac

if [ "$MAX_RUNTIME_SECONDS" -lt 60 ]; then
  die "--max-runtime-seconds must be at least 60"
fi

RUN_DIR="${RUN_ROOT%/}/job-${JOB_ID}-$(date -u +%Y%m%dT%H%M%SZ)"

if [ "$MODE" = "plan-only" ]; then
  cat <<EOF_PLAN
phase=$PHASE
mode=plan-only
dispatch_would_target_job_id=$JOB_ID
expected_model=${EXPECTED_MODEL:-<not-asserted>}
run_root=$RUN_ROOT
run_dir=$RUN_DIR
max_runtime_seconds=$MAX_RUNTIME_SECONDS

NO-RUN PLAN:
  1. Read-only CT203 DB preflight.
  2. Refuse unless target job is queued and has zero job_results rows.
  3. Refuse unless requested_model is allowlisted.
  4. Read-only scheduler and persistent worker default-off checks.
  5. Read-only PVESO Ollama localhost-only and runner checks.
  6. Create durable run_dir before long execution in a later approved phase.
  7. Run existing adapter/helper only in a later explicitly approved phase.
  8. Complete DB lifecycle exactly once in a later explicitly approved phase.
  9. Run read-only postflight and timeout recovery classification.

E3O_NO_RUN_ARTIFACT: no CT203, PVESO, Ollama, model, helper, adapter, or DB action was performed.
EOF_PLAN
  exit 0
fi

if [ "$MODE" = "execute-approved" ]; then
  supplied="${APC_OPERATOR_DISPATCH_APPROVAL:-}"
  if [ "$supplied" != "$REQUIRED_EXEC_APPROVAL" ]; then
    echo "E3O_NO_RUN_ARTIFACT_EXECUTION_DISABLED"
    echo "missing_or_wrong_approval_marker=true"
    echo "required=$REQUIRED_EXEC_APPROVAL"
    exit 64
  fi

  echo "E3O_NO_RUN_ARTIFACT_EXECUTION_DISABLED"
  echo "approval_marker_present=true"
  echo "execution_is_intentionally_disabled_until_E3P=true"
  echo "job_id=$JOB_ID"
  echo "run_dir=$RUN_DIR"
  exit 64
fi

die "unhandled mode: $MODE"
