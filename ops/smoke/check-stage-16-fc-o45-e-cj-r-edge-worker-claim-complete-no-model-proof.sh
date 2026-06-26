#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cj-p-cj-q-r4-edge-worker-claim-complete-no-model-proof.md"

test -f "$DOC"

grep -Fq "Edge-Worker Claim/Complete Deterministic No-Model Proof" "$DOC"
grep -Fq "1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2" "$DOC"
grep -Fq "stage-16-fc-o45-e-cj-p-edge-worker-claim-short-circuit-deploy-20260626T041007Z" "$DOC"
grep -Fq "LAPTOP_QUEUE_INTERNAL_TOKEN" "$DOC"
grep -Fq "X-Laptop-Queue-Token" "$DOC"
grep -Fq "POST /internal/edge-worker/jobs/claim" "$DOC"
grep -Fq "claimed" "$DOC"
grep -Fq "companion_execution.mode=deterministic_exact_answer_short_circuit" "$DOC"
grep -Fq "companion_execution.complete_without_model=true" "$DOC"
grep -Fq "companion_execution.model=backend-deterministic/no-model" "$DOC"
grep -Fq "companion_execution.model_call_allowed=false" "$DOC"
grep -Fq "companion_execution.semantic_exact_marker_pass=true" "$DOC"
grep -Fq "POST /internal/edge-worker/jobs/576/complete" "$DOC"
grep -Fq "id=576" "$DOC"
grep -Fq "status=completed" "$DOC"
grep -Fq "attempts=1" "$DOC"
grep -Fq "result_rows=1" "$DOC"
grep -Fq "FC-O45-E-CJ-Q-INTERNAL-CLAIM-COMPLETE-OK" "$DOC"
grep -Fq "No frontend patch" "$DOC"
grep -Fq "no PVESO call" "$DOC"
grep -Fq "no Ollama/model endpoint call" "$DOC"
grep -Fq "persistent workers disabled" "$DOC"

echo "PASS stage-16-fc-o45-e-cj-r edge-worker claim/complete no-model proof record smoke"
