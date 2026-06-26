#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-ck-d-manual-wrapper-runtime-proof.md"

test -f "$DOC"

grep -Fq "Manual Wrapper Runtime Proof" "$DOC"
grep -Fq "1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2" "$DOC"
grep -Fq "7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419" "$DOC"
grep -Fq "265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a" "$DOC"
grep -Fq "481bbae24f683880bdbc67fffc8ae3605603aba84913613db7f5b2f7ace00595" "$DOC"
grep -Fq "Fresh job id:" "$DOC"
grep -Fq "579" "$DOC"
grep -Fq "FC-O45-E-CK-D-WRAPPER-RUNTIME-OK" "$DOC"
grep -Fq "/opt/edge-queue-controller/ops/workers/run-deterministic-companion-systemd-once.sh" "$DOC"
grep -Fq "edge-deterministic-companion-worker-once@579.service" "$DOC"
grep -Fq "env_file_created=yes" "$DOC"
grep -Fq "service_result=success" "$DOC"
grep -Fq "service_exec_main_status=0" "$DOC"
grep -Fq "backend-deterministic/no-model" "$DOC"
grep -Fq "env_file_removed=yes" "$DOC"
grep -Fq "deterministic_companion_systemd_once_done=yes" "$DOC"
grep -Fq "result_rows=1" "$DOC"
grep -Fq "error=None" "$DOC"
grep -Fq "no service enable" "$DOC"
grep -Fq "no timer install" "$DOC"
grep -Fq "no persistent-worker activation" "$DOC"
grep -Fq "no PVESO call" "$DOC"
grep -Fq "no Ollama/model endpoint call" "$DOC"

echo "PASS stage-16-fc-o45-e-ck-e manual wrapper runtime proof record smoke"
