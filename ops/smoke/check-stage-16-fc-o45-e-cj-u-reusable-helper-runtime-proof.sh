#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cj-s-cj-t-reusable-helper-runtime-proof.md"

test -f "$DOC"

grep -Fq "Reusable Helper Runtime Proof" "$DOC"
grep -Fq "ops/workers/run-deterministic-companion-exact-once.py" "$DOC"
grep -Fq "7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419" "$DOC"
grep -Fq "LAPTOP_QUEUE_INTERNAL_TOKEN" "$DOC"
grep -Fq "X-Laptop-Queue-Token" "$DOC"
grep -Fq "claim_response_key=claimed" "$DOC"
grep -Fq "complete_without_model=true" "$DOC"
grep -Fq "id=577" "$DOC"
grep -Fq "status=completed" "$DOC"
grep -Fq "attempts=1" "$DOC"
grep -Fq "result_rows=1" "$DOC"
grep -Fq "backend-deterministic/no-model" "$DOC"
grep -Fq "FC-O45-E-CJ-T-HELPER-RUNTIME-OK" "$DOC"
grep -Fq "model_endpoint_called=false" "$DOC"
grep -Fq "pveso_called=false" "$DOC"
grep -Fq "does not call PVESO, Ollama, or a model endpoint" "$DOC"
grep -Fq "persistent workers and timers disabled" "$DOC"

echo "PASS stage-16-fc-o45-e-cj-u reusable helper runtime proof record smoke"
