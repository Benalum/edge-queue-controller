#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== laptop queue helper smoke ==="

python3 - <<'PY'
import os
import time

from edge_modules.laptop_queue import LaptopQueueClient

suffix = f"{int(time.time())}-{os.getpid()}"
user_id = f"s5e3-user-{suffix}"
node_id = f"s5e3-node-{suffix}"
worker_id = f"s5e3-worker-{suffix}"
job_ok_id = f"s5e3-job-ok-{suffix}"
job_fail_id = f"s5e3-job-fail-{suffix}"

client = LaptopQueueClient()
job_ids = [job_ok_id, job_fail_id]

try:
    client.cleanup_synthetic(
        user_id=user_id,
        node_id=node_id,
        worker_id=worker_id,
        job_ids=job_ids,
    )

    for table in ["app_jobs", "app_workers", "app_worker_nodes", "app_users"]:
        assert client.table_exists(table), table

    client.create_synthetic_user(
        user_id=user_id,
        email=f"{user_id}@example.local",
        display_name="Stage 5E-3 Synthetic User",
    )
    client.create_synthetic_worker_node(
        node_id=node_id,
        name="Stage 5E-3 Synthetic Node",
        capabilities={"job_types": ["ollama_chat"]},
    )
    client.create_synthetic_worker(
        worker_id=worker_id,
        node_id=node_id,
        name="Stage 5E-3 Synthetic Worker",
        capabilities={"job_types": ["ollama_chat"]},
    )

    client.create_job(
        job_id=job_ok_id,
        user_id=user_id,
        job_type="ollama_chat",
        requested_model="stage-5e3-synthetic-model",
        payload={"prompt": "synthetic success job"},
    )
    client.create_job(
        job_id=job_fail_id,
        user_id=user_id,
        job_type="ollama_chat",
        requested_model="stage-5e3-synthetic-model",
        payload={"prompt": "synthetic failed job"},
    )

    claimed = client.claim_next_job(worker_id=worker_id, job_type="ollama_chat")
    assert claimed, "No job claimed"
    assert claimed["id"] == job_ok_id, claimed
    assert claimed["status"] == "running", claimed
    assert claimed["assigned_worker_id"] == worker_id, claimed

    worker_state = client.get_worker_state(worker_id=worker_id)
    assert worker_state == f"busy|{job_ok_id}", worker_state
    print("OK: helper claimed first queued job and marked worker busy")

    completed = client.complete_job(
        job_id=job_ok_id,
        worker_id=worker_id,
        ok=True,
        result={"reply": "synthetic helper complete reply", "model": "stage-5e3-synthetic-model"},
    )
    assert completed["id"] == job_ok_id, completed
    assert completed["status"] == "complete", completed

    reply = client.get_job_json_field(job_id=job_ok_id, field_name="reply")
    assert reply == "synthetic helper complete reply", reply

    worker_state = client.get_worker_state(worker_id=worker_id)
    assert worker_state == "idle|", worker_state
    print("OK: helper completed job and returned worker idle")

    claimed_fail = client.claim_next_job(worker_id=worker_id, job_type="ollama_chat")
    assert claimed_fail, "No failure job claimed"
    assert claimed_fail["id"] == job_fail_id, claimed_fail
    assert claimed_fail["status"] == "running", claimed_fail

    failed = client.complete_job(
        job_id=job_fail_id,
        worker_id=worker_id,
        ok=False,
        error_text="synthetic helper failure",
    )
    assert failed["id"] == job_fail_id, failed
    assert failed["status"] == "failed", failed

    error_text = client.get_job_error(job_id=job_fail_id)
    assert error_text == "synthetic helper failure", error_text

    worker_state = client.get_worker_state(worker_id=worker_id)
    assert worker_state == "idle|", worker_state
    print("OK: helper failed job and returned worker idle")

finally:
    client.cleanup_synthetic(
        user_id=user_id,
        node_id=node_id,
        worker_id=worker_id,
        job_ids=job_ids,
    )

leftovers = client.synthetic_leftover_count(
    user_id=user_id,
    node_id=node_id,
    worker_id=worker_id,
    job_ids=job_ids,
)

if leftovers:
    raise SystemExit(f"FAIL: helper smoke left {leftovers} synthetic row(s)")

print("PASS: laptop queue helper smoke passed and cleaned up")
PY
