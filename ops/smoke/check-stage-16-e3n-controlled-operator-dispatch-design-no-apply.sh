#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT/docs/stage-16-e3n-controlled-operator-dispatch-design-no-apply.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

must_contain() {
  local needle="$1"
  grep -F "$needle" "$DOC" >/dev/null || fail "missing required text: $needle"
}

must_not_contain() {
  local needle="$1"
  if grep -F "$needle" "$DOC" >/dev/null; then
    fail "forbidden text present: $needle"
  fi
}

test -f "$DOC" || fail "missing doc: $DOC"

must_contain "Stage 16 E3N"
must_contain "Controlled Operator Dispatch Design No-Apply"
must_contain "E3N is no-apply design only"
must_contain "No DB mutation"
must_contain "No scheduler activation"
must_contain "No persistent worker activation"
must_contain "No model endpoint call"
must_contain "No public exposure of PVESO or Ollama"
must_contain "Single-job dispatch by job ID"
must_contain "Idempotency rules"
must_contain "Timeout and recovery classification"
must_contain "Tailscale SSH handling"
must_contain "Output capture requirements"
must_contain "PVESO and Ollama boundary"
must_contain "Scheduler and worker boundary"
must_contain "Guardrails against duplicate job_results rows"
must_contain "E3O: Add controlled operator dispatch artifact no-run"
must_contain "E3P: Insert one fresh synthetic queued job and run the controlled dispatch artifact with explicit approval"

test -f "$ROOT/ops/model/pveso-one-shot-generate.sh" || fail "missing one-shot adapter"
test -f "$ROOT/ops/model/manual-complete-queued-job-via-pveso-adapter.sh" || fail "missing manual completion helper"

must_not_contain "E3N applied"
must_not_contain "scheduler enabled"
must_not_contain "persistent workers enabled"
must_not_contain "public Ollama endpoint"

echo "PASS stage-16-e3n-controlled-operator-dispatch-design-no-apply smoke"
