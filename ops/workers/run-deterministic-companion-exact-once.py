#!/usr/bin/env python3
"""Bounded one-shot deterministic Companion exact-answer worker client.

This helper talks only to CT203 internal edge-worker HTTP endpoints.

It is intentionally narrow:
- claim exactly one approved job id
- require the claim response to include deterministic companion_execution
- complete with backend-deterministic/no-model
- never call Ollama or any model endpoint
- never print token values
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from typing import Any


class WorkerClientError(RuntimeError):
    pass


def _json_post(base_url: str, path: str, token: str, payload: dict[str, Any], timeout: int = 10) -> dict[str, Any]:
    if not token:
        raise WorkerClientError("internal worker token is required but was not provided")

    url = base_url.rstrip("/") + path
    request = urllib.request.Request(
        url,
        data=json.dumps(payload, sort_keys=True).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "X-Laptop-Queue-Token": token,
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            body = response.read().decode("utf-8", errors="replace")
            data = json.loads(body)
            if response.status != 200:
                raise WorkerClientError(f"HTTP {response.status} for {path}")
            return data
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise WorkerClientError(f"HTTP {exc.code} for {path}: {body}") from exc


def _claimed_job_from_response(claim_response: dict[str, Any]) -> dict[str, Any]:
    if claim_response.get("ok") is not True:
        raise WorkerClientError("claim response was not ok")

    claimed = claim_response.get("claimed")
    if isinstance(claimed, dict):
        return claimed

    legacy_job = claim_response.get("job")
    if isinstance(legacy_job, dict):
        return legacy_job

    raise WorkerClientError("claim response did not include claimed/job object")


def _require_bool(value: Any, expected: bool, field: str) -> None:
    if value is not expected:
        raise WorkerClientError(f"{field} expected {expected!r}, got {value!r}")


def _validate_claimed_job(
    claimed: dict[str, Any],
    *,
    job_id: int,
    expected_marker: str,
    expected_result_model: str,
) -> dict[str, Any]:
    if int(claimed.get("id") or -1) != job_id:
        raise WorkerClientError(f"claimed job id mismatch: {claimed.get('id')!r}")

    if claimed.get("status") != "running":
        raise WorkerClientError(f"claimed job is not running: {claimed.get('status')!r}")

    if int(claimed.get("attempts") or 0) != 1:
        raise WorkerClientError(f"claimed job attempts must be 1: {claimed.get('attempts')!r}")

    if claimed.get("job_type") != "companion.chat":
        raise WorkerClientError(f"claimed job type mismatch: {claimed.get('job_type')!r}")

    companion_execution = claimed.get("companion_execution")
    if not isinstance(companion_execution, dict):
        raise WorkerClientError("claimed job missing companion_execution payload")

    if companion_execution.get("mode") != "deterministic_exact_answer_short_circuit":
        raise WorkerClientError("companion_execution mode mismatch")

    _require_bool(companion_execution.get("complete_without_model"), True, "complete_without_model")
    _require_bool(companion_execution.get("model_required"), False, "model_required")
    _require_bool(companion_execution.get("model_call_allowed"), False, "model_call_allowed")
    _require_bool(companion_execution.get("semantic_exact_marker_pass"), True, "semantic_exact_marker_pass")

    if companion_execution.get("model") != expected_result_model:
        raise WorkerClientError(f"result model mismatch: {companion_execution.get('model')!r}")

    if companion_execution.get("response_text") != expected_marker:
        raise WorkerClientError("deterministic response text did not match expected marker")

    return companion_execution


def run_once(
    *,
    base_url: str,
    token: str,
    job_id: int,
    worker_id: str,
    allowed_model: str,
    expected_marker: str,
    expected_result_model: str = "backend-deterministic/no-model",
    timeout: int = 10,
) -> dict[str, Any]:
    claim_payload = {
        "worker_id": worker_id,
        "claim_job_ids": [job_id],
        "allowed_models": [allowed_model],
    }

    claim_response = _json_post(base_url, "/internal/edge-worker/jobs/claim", token, claim_payload, timeout=timeout)
    claimed = _claimed_job_from_response(claim_response)
    companion_execution = _validate_claimed_job(
        claimed,
        job_id=job_id,
        expected_marker=expected_marker,
        expected_result_model=expected_result_model,
    )

    complete_payload = {
        "worker_id": worker_id,
        "model": companion_execution["model"],
        "response_text": companion_execution["response_text"],
        "response_json": {
            "ok": True,
            "stage": "stage16-fc-o45-e-cj-s",
            "claimed_companion_execution": companion_execution,
            "completed_via": "/internal/edge-worker/jobs/{job_id}/complete",
            "model_endpoint_called": False,
            "pveso_called": False,
        },
        "error": None,
    }

    complete_response = _json_post(
        base_url,
        f"/internal/edge-worker/jobs/{job_id}/complete",
        token,
        complete_payload,
        timeout=timeout,
    )

    if complete_response.get("ok") is not True:
        raise WorkerClientError("complete response was not ok")

    return {
        "ok": True,
        "stage": "stage16-fc-o45-e-cj-s",
        "job_id": job_id,
        "worker_id": worker_id,
        "claim_response_key": "claimed" if "claimed" in claim_response else "job",
        "complete_without_model": True,
        "result_model": expected_result_model,
        "response_text": expected_marker,
        "model_endpoint_called": False,
        "pveso_called": False,
        "claim": claim_response,
        "complete": complete_response,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Run one deterministic exact-answer Companion job without model calls.")
    parser.add_argument("--base-url", default=os.getenv("EDGE_WORKER_BASE_URL", "http://127.0.0.1:7070"))
    parser.add_argument("--job-id", type=int, required=True)
    parser.add_argument("--worker-id", required=True)
    parser.add_argument("--allowed-model", default="qwen2.5:0.5b")
    parser.add_argument("--expected-marker", required=True)
    parser.add_argument("--expected-result-model", default="backend-deterministic/no-model")
    parser.add_argument("--timeout", type=int, default=10)
    parser.add_argument("--token-env", default="LAPTOP_QUEUE_INTERNAL_TOKEN")
    args = parser.parse_args(argv)

    token = os.getenv(args.token_env, "")
    if not token:
        raise WorkerClientError(f"{args.token_env} is required but is not set")

    result = run_once(
        base_url=args.base_url,
        token=token,
        job_id=args.job_id,
        worker_id=args.worker_id,
        allowed_model=args.allowed_model,
        expected_marker=args.expected_marker,
        expected_result_model=args.expected_result_model,
        timeout=args.timeout,
    )

    safe_summary = {
        "ok": result["ok"],
        "stage": result["stage"],
        "job_id": result["job_id"],
        "worker_id": result["worker_id"],
        "claim_response_key": result["claim_response_key"],
        "complete_without_model": result["complete_without_model"],
        "result_model": result["result_model"],
        "response_text": result["response_text"],
        "model_endpoint_called": result["model_endpoint_called"],
        "pveso_called": result["pveso_called"],
    }
    print(json.dumps(safe_summary, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except WorkerClientError as exc:
        print(f"REFUSE_DETERMINISTIC_COMPANION_WORKER_CLIENT: {exc}", file=sys.stderr)
        raise SystemExit(2)
