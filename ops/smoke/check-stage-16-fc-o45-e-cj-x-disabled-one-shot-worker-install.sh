#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cj-w-r3-disabled-one-shot-worker-install.md"

test -f "$DOC"

grep -Fq "Disabled One-Shot Worker Install" "$DOC"
grep -Fq "/opt/edge-queue-controller/ops/workers/run-deterministic-companion-exact-once.py" "$DOC"
grep -Fq "7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419" "$DOC"
grep -Fq "/etc/systemd/system/edge-deterministic-companion-worker-once@.service" "$DOC"
grep -Fq "265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a" "$DOC"
grep -Fq "daemon-reload" "$DOC"
grep -Fq "static" "$DOC"
grep -Fq "inactive" "$DOC"
grep -Fq "stage-16-fc-o45-e-cj-w-r3-install-disabled-one-shot-worker-20260626T043409Z" "$DOC"
grep -Fq "1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2" "$DOC"
grep -Fq "no service start" "$DOC"
grep -Fq "no service enable" "$DOC"
grep -Fq "no timer install" "$DOC"
grep -Fq "no model/helper/Ollama call" "$DOC"
grep -Fq "one bounded systemd start proof" "$DOC"

echo "PASS stage-16-fc-o45-e-cj-x disabled one-shot worker install record smoke"
