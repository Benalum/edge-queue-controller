#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-ck-g-selector-wrapper-install.md"

test -f "$DOC"

grep -Fq "Marker-Selected Selector Wrapper Install" "$DOC"
grep -Fq "/opt/edge-queue-controller/ops/workers/run-next-deterministic-companion-systemd-once.sh" "$DOC"
grep -Fq "1115a5c2e6759d75f9cbfe92b80b668659a91e86f58f6c5da68ee26532e52c41" "$DOC"
grep -Fq "stage-16-fc-o45-e-ck-g-install-selector-wrapper-20260626T045045Z" "$DOC"
grep -Fq "1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2" "$DOC"
grep -Fq "7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419" "$DOC"
grep -Fq "265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a" "$DOC"
grep -Fq "481bbae24f683880bdbc67fffc8ae3605603aba84913613db7f5b2f7ace00595" "$DOC"
grep -Fq "Template enabled state:" "$DOC"
grep -Fq "static" "$DOC"
grep -Fq "Example instance active state:" "$DOC"
grep -Fq "inactive" "$DOC"
grep -Fq "No persistent, general, or deterministic worker process was active" "$DOC"
grep -Fq "job_type=companion.chat" "$DOC"
grep -Fq "status=queued" "$DOC"
grep -Fq "attempts=0" "$DOC"
grep -Fq "result_rows=0" "$DOC"
grep -Fq "refuses if zero jobs match" "$DOC"
grep -Fq "refuses if multiple jobs match" "$DOC"
grep -Fq "does not insert jobs" "$DOC"
grep -Fq "no service start" "$DOC"
grep -Fq "no service enable" "$DOC"
grep -Fq "no timer install" "$DOC"
grep -Fq "no model/helper/Ollama call" "$DOC"
grep -Fq "Run one fresh exact-answer Companion job through the installed selector wrapper" "$DOC"

echo "PASS stage-16-fc-o45-e-ck-h selector wrapper install record smoke"
