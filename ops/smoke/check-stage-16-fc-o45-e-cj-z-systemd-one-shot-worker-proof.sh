#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cj-y-systemd-one-shot-deterministic-companion-worker-proof.md"

test -f "$DOC"

grep -Fq "Systemd One-Shot Deterministic Companion Worker Proof" "$DOC"
grep -Fq "/opt/edge-queue-controller/ops/workers/run-deterministic-companion-exact-once.py" "$DOC"
grep -Fq "7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419" "$DOC"
grep -Fq "/etc/systemd/system/edge-deterministic-companion-worker-once@.service" "$DOC"
grep -Fq "265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a" "$DOC"
grep -Fq "static" "$DOC"
grep -Fq "1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2" "$DOC"
grep -Fq "Fresh job id:" "$DOC"
grep -Fq "578" "$DOC"
grep -Fq "edge-deterministic-companion-worker-once@578.service" "$DOC"
grep -Fq "service_result=success" "$DOC"
grep -Fq "service_exec_main_status=0" "$DOC"
grep -Fq "status=completed" "$DOC"
grep -Fq "attempts=1" "$DOC"
grep -Fq "result_rows=1" "$DOC"
grep -Fq "backend-deterministic/no-model" "$DOC"
grep -Fq "FC-O45-E-CJ-Y-SYSTEMD-ONESHOT-OK" "$DOC"
grep -Fq "error=None" "$DOC"
grep -Fq "no PVESO call" "$DOC"
grep -Fq "no Ollama/model endpoint call" "$DOC"
grep -Fq "no service enable" "$DOC"
grep -Fq "no timer install" "$DOC"
grep -Fq "no persistent-worker activation" "$DOC"

echo "PASS stage-16-fc-o45-e-cj-z systemd one-shot deterministic Companion worker proof record smoke"
