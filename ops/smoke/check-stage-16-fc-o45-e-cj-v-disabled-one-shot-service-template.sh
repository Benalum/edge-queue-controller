#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

UNIT="ops/systemd/edge-deterministic-companion-worker-once@.service"
HELPER="ops/workers/run-deterministic-companion-exact-once.py"
DOC="docs/stage-16-fc-o45-e-cj-v-disabled-one-shot-deterministic-companion-worker-service-template.md"

test -f "$UNIT"
test -f "$HELPER"
test -x "$HELPER"
test -f "$DOC"

grep -Fq "Description=Edge deterministic Companion exact-answer worker once for job %i" "$UNIT"
grep -Fq "Type=oneshot" "$UNIT"
grep -Fq "Requires=edge-queue-controller.service" "$UNIT"
grep -Fq "EnvironmentFile=/etc/edge-queue-controller/edge-queue-controller.env" "$UNIT"
grep -Fq "EnvironmentFile=/run/edge-queue-controller/deterministic-companion-worker/%i.env" "$UNIT"
grep -Fq "EDGE_EXPECTED_MARKER" "$UNIT"
grep -Fq "run-deterministic-companion-exact-once.py" "$UNIT"
grep -Fq -- "--job-id %i" "$UNIT"
grep -Fq -- "--token-env LAPTOP_QUEUE_INTERNAL_TOKEN" "$UNIT"
grep -Fq "NoNewPrivileges=true" "$UNIT"
grep -Fq "ProtectSystem=strict" "$UNIT"
grep -Fq "ReadWritePaths=/var/lib/edge-queue-controller /run/edge-queue-controller" "$UNIT"
grep -Fq "# Intentionally no WantedBy" "$UNIT"

if grep -Eq '^WantedBy=' "$UNIT"; then
  echo "REFUSE_UNIT_HAS_WANTEDBY"
  exit 1
fi

grep -Fq "Disabled One-Shot Deterministic Companion Worker Service Template" "$DOC"
grep -Fq "edge-deterministic-companion-worker-once@<job_id>.service" "$DOC"
grep -Fq "EDGE_EXPECTED_MARKER" "$DOC"
grep -Fq "LAPTOP_QUEUE_INTERNAL_TOKEN" "$DOC"
grep -Fq "X-Laptop-Queue-Token" "$DOC"
grep -Fq "It must not be enabled" "$DOC"
grep -Fq "never call PVESO, Ollama, or a model endpoint" "$DOC"
grep -Fq "without enabling it" "$DOC"

python3 - <<'PY'
from pathlib import Path

unit = Path("ops/systemd/edge-deterministic-companion-worker-once@.service").read_text()

required_sections = ["[Unit]", "[Service]", "[Install]"]
for section in required_sections:
    assert section in unit, section

assert "Type=oneshot" in unit
assert "WantedBy=" not in unit
assert "ExecStart=/usr/bin/python3 /opt/edge-queue-controller/ops/workers/run-deterministic-companion-exact-once.py" in unit
assert "--expected-marker ${EDGE_EXPECTED_MARKER}" in unit
assert "--token-env LAPTOP_QUEUE_INTERNAL_TOKEN" in unit
assert "Persistent" not in unit
assert "timer" not in unit.lower()

print("disabled_one_shot_service_template_static_smoke_ok=yes")
PY

echo "PASS stage-16-fc-o45-e-cj-v disabled one-shot service template smoke"
