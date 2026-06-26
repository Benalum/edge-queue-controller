#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

WRAPPER="ops/workers/run-deterministic-companion-systemd-once.sh"
DOC="docs/stage-16-fc-o45-e-ck-a-manual-deterministic-companion-systemd-wrapper.md"

test -f "$WRAPPER"
test -x "$WRAPPER"
test -f "$DOC"

grep -Fq "Usage:" "$WRAPPER"
grep -Fq -- "--job-id" "$WRAPPER"
grep -Fq -- "--expected-marker" "$WRAPPER"
grep -Fq "backend-deterministic/no-model" "$WRAPPER"
grep -Fq "edge-deterministic-companion-worker-once@" "$WRAPPER"
grep -Fq "/run/edge-queue-controller/deterministic-companion-worker" "$WRAPPER"
grep -Fq "REFUSE_JOB_NOT_QUEUED" "$WRAPPER"
grep -Fq "REFUSE_EXPECTED_MARKER_NOT_IN_PROMPT" "$WRAPPER"
grep -Fq "systemctl start" "$WRAPPER"
grep -Fq "service_result" "$WRAPPER"
grep -Fq "final_result_model" "$WRAPPER"
grep -Fq "env_file_removed=yes" "$WRAPPER"
grep -Fq "deterministic_companion_systemd_once_done=yes" "$WRAPPER"

grep -Fq "Manual Deterministic Companion Systemd Wrapper" "$DOC"
grep -Fq "ops/workers/run-deterministic-companion-systemd-once.sh" "$DOC"
grep -Fq "job is queued" "$DOC"
grep -Fq "job attempts are zero" "$DOC"
grep -Fq "result_rows=1" "$DOC"
grep -Fq "backend-deterministic/no-model" "$DOC"
grep -Fq "does not insert jobs" "$DOC"
grep -Fq "does not enable a service" "$DOC"
grep -Fq "does not install or enable a timer" "$DOC"
grep -Fq "does not activate a persistent worker" "$DOC"
grep -Fq "does not call PVESO, Ollama, or any model endpoint" "$DOC"

bash -n "$WRAPPER"

echo "PASS stage-16-fc-o45-e-ck-a manual deterministic Companion systemd wrapper smoke"
