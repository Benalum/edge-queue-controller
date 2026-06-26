#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cj-k-cj-l-deterministic-exact-answer-live-proof.md"

test -f "$DOC"

grep -Fq "Deterministic Exact-Answer Live Proof" "$DOC"
grep -Fq "313b4eb9f2cd0577d8fb5fa2c5c93bc1fadcdc4dfa3418b113af7fa9c64cda46" "$DOC"
grep -Fq "stage-16-fc-o45-e-cj-k-deterministic-exact-answer-short-circuit-deploy-20260626T040230Z" "$DOC"
grep -Fq "edge-queue-controller.service" "$DOC"
grep -Fq "FC-O45-E-CJ-K-LIVE-SHORT-CIRCUIT-OK" "$DOC"
grep -Fq "id=575" "$DOC"
grep -Fq "FC-O45-E-CJ-L-SHORT-CIRCUIT-OK" "$DOC"
grep -Fq "status=completed" "$DOC"
grep -Fq "attempts=1" "$DOC"
grep -Fq "result_rows=1" "$DOC"
grep -Fq "backend-deterministic/no-model" "$DOC"
grep -Fq "model_call_allowed=false" "$DOC"
grep -Fq "semantic_exact_marker_pass=true" "$DOC"
grep -Fq "No frontend patch" "$DOC"
grep -Fq "no PVESO call" "$DOC"
grep -Fq "no Ollama/model/helper call" "$DOC"
grep -Fq "Wire the deterministic exact-answer short-circuit" "$DOC"

echo "PASS stage-16-fc-o45-e-cj-m deterministic exact-answer live proof record smoke"
