#!/usr/bin/env bash
set -euo pipefail

python3 -m py_compile edge_controller.py

python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "STAGE_14J_LJ_CURRENT_PVEW_STATUS_MODEL_V1",
    '"id": "pvew"',
    '"id": "vm-200"',
    '"id": "ct-203"',
    '"id": "ct-204"',
    '"state": "planned"',
    '"schema_version": 2',
    "Legacy PVESO/laptop power automation is parked",
    "Model workers are intentionally parked",
    "Current public status should not degrade because retired PVESO/CT101/laptop",
]

for needle in required:
    if needle not in text:
        raise SystemExit(f"missing required LJ marker: {needle}")

uncached_start = text.index("def _system_status_uncached():")
uncached_end = text.index("@app.post(\"/system/pveso/boot\")", uncached_start)
uncached = text[uncached_start:uncached_end]

for forbidden in [
    '"id": "pveso"',
    '"id": "ct-101"',
    "_system_ct101_laptop_queue_worker_status(",
    "_system_frontend_wrapper_status(checked_at)",
    "_system_queue_status_from_worker(checked_at, ct101_worker_service)",
    "_system_power_automation_status(checked_at)",
    'pveso_state == "offline"',
]:
    if forbidden in uncached:
        raise SystemExit(f"legacy degraded-status marker remains in _system_status_uncached: {forbidden}")

normalized_start = text.index("def _system_status_normalized_block(nodes, services):")
normalized_end = text.index("# STAGE_5G24_CT101_MANAGED_WORKER_STATUS_V1", normalized_start)
normalized = text[normalized_start:normalized_end]

for forbidden in [
    'node_state("pveso")',
    'node_state("ct-101")',
    '"id": "ct101-laptop-queue-worker"',
    '"CT101 Laptop Queue Worker"',
]:
    if forbidden in normalized:
        raise SystemExit(f"legacy normalized marker remains: {forbidden}")

print("PASS check-phase-14j-lj-current-pvew-status-model-no-live-apply")
PY
