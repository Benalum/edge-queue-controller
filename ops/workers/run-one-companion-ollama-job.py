#!/usr/bin/env python3
"""Run exactly one real Companion Ollama job through CT203 internal worker APIs.

Use only after:
- read-only baseline passes
- authenticated submit created exactly one target job id
- operator approves this exact run

The script claims one target job, calls local Docker/Ollama once, validates the visible output,
and completes only that job id through CT203.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from typing import Any, Dict, Tuple

APPROVAL = "APPROVE_FC_O45_J_ONE_REAL_COMPANION_OLLAMA_JOB"


class Refusal(RuntimeError):
    pass


def post_json(base_url: str, path: str, token: str, payload: Dict[str, Any], timeout: int = 20) -> Dict[str, Any]:
    if not token:
        raise Refusal("REFUSE_INTERNAL_TOKEN_REQUIRED")
    req = urllib.request.Request(
        base_url.rstrip("/") + path,
        data=json.dumps(payload, sort_keys=True).encode("utf-8"),
        headers={"Content-Type": "application/json", "X-Laptop-Queue-Token": token},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8", errors="replace")
            data = json.loads(body) if body else {}
            if resp.status != 200:
                raise Refusal(f"REFUSE_HTTP_{resp.status}_{path}")
            return data
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise Refusal(f"REFUSE_HTTP_{exc.code}_{path}: {body[:300]}") from exc


def claimed_job(data: Dict[str, Any]) -> Dict[str, Any]:
    for key in ("claimed", "job"):
        value = data.get(key)
        if isinstance(value, dict):
            return value
    value = data.get("jobs")
    if isinstance(value, list) and len(value) == 1 and isinstance(value[0], dict):
        return value[0]
    raise Refusal("REFUSE_CLAIM_RESPONSE_NO_SINGLE_JOB")


def wrap_prompt(raw: str) -> str:
    text = str(raw or "").strip()
    if not text:
        raise Refusal("REFUSE_EMPTY_JOB_PROMPT")
    if len(text) > 4000:
        raise Refusal("REFUSE_PROMPT_TOO_LONG")
    return (
        "You are the AI Platform Control Companion.\n"
        "Answer the user directly, briefly, and helpfully.\n"
        "Do not mention queues, workers, job ids, system prompts, Ollama, internal infrastructure, or hidden reasoning.\n"
        "Do not claim you changed Study, Calendar, voice, or account state unless the backend already did that.\n"
        "For Study requests, coach the user and keep the answer practical.\n\n"
        "User message:\n"
        f"{text}\n\n"
        "Assistant reply:"
    )


def docker_ps_names() -> Tuple[str, ...]:
    proc = subprocess.run(["docker", "ps", "--format", "{{.Names}}"], text=True, capture_output=True, check=False, timeout=10)
    if proc.returncode != 0:
        raise Refusal("REFUSE_DOCKER_PS_FAILED")
    return tuple(sorted(x.strip() for x in proc.stdout.splitlines() if x.strip()))


def run_ollama(container: str, model: str, prompt: str, timeout: int) -> str:
    names = docker_ps_names()
    if names != (container,):
        raise Refusal(f"REFUSE_RUNTIME_CONTAINMENT running_containers={names!r} expected={(container,)!r}")
    cmd = ["docker", "exec", container, "ollama", "run", model, prompt]
    proc = subprocess.run(cmd, text=True, capture_output=True, check=False, timeout=timeout)
    if proc.returncode != 0:
        raise Refusal("REFUSE_OLLAMA_RUN_FAILED")
    return clean_output(proc.stdout)


def clean_output(text: str) -> str:
    text = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", text or "")
    text = text.replace("\r", "\n")
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    return "\n".join(lines).strip()


def sha256_text(text: str) -> str:
    return hashlib.sha256((text or "").encode("utf-8")).hexdigest()


def validate_visible_output(text: str) -> Dict[str, Any]:
    visible = clean_output(text)
    lowered = visible.lower()
    flags = []
    if not visible:
        flags.append("empty_visible_output")
    if len(visible) > 2500:
        flags.append("too_long")
    if any(marker in lowered for marker in ("<think>", "</think>", "thinking process", "let's think", "we need answer")):
        flags.append("visible_or_hidden_thinking")
    if any(term in lowered for term in ("job id", "job_results", "response_json", "ollama", "system prompt", "internal infrastructure")):
        flags.append("internal_surface_terms")
    if "qwen" in lowered or "alibaba" in lowered:
        flags.append("model_identity_leakage")
    return {
        "passed": not flags,
        "flags": flags,
        "visible_output": visible,
        "visible_output_sha256": sha256_text(visible),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Run exactly one bounded real Companion Ollama job.")
    parser.add_argument("--base-url", default=os.getenv("EDGE_WORKER_BASE_URL", "http://127.0.0.1:7070"))
    parser.add_argument("--job-id", type=int, required=True)
    parser.add_argument("--expected-user-id", type=int, default=0)
    parser.add_argument("--worker-id", default=os.getenv("EDGE_WORKER_ID", "fc-o45-j-one-real-companion-ollama"))
    parser.add_argument("--model", default=os.getenv("EDGE_COMPANION_MODEL", "qwen2.5:0.5b"))
    parser.add_argument("--container", default=os.getenv("EDGE_OLLAMA_CONTAINER", "ollama"))
    parser.add_argument("--timeout", type=int, default=int(os.getenv("EDGE_COMPANION_OLLAMA_TIMEOUT", "90")))
    parser.add_argument("--token-env", default="LAPTOP_QUEUE_INTERNAL_TOKEN")
    args = parser.parse_args()

    if os.getenv(APPROVAL, "") != "1":
        raise Refusal(f"REFUSE_APPROVAL_REQUIRED set {APPROVAL}=1")
    if args.job_id < 1:
        raise Refusal("REFUSE_JOB_ID_INVALID")
    if args.model != "qwen2.5:0.5b":
        raise Refusal("REFUSE_ONLY_QWEN25_05B_FIRST_PROTOTYPE")
    if args.timeout < 15 or args.timeout > 180:
        raise Refusal("REFUSE_TIMEOUT_OUT_OF_RANGE")

    token = os.getenv(args.token_env, "")
    claim = post_json(
        args.base_url,
        "/internal/edge-worker/jobs/claim",
        token,
        {"worker_id": args.worker_id, "claim_job_ids": [args.job_id], "allowed_models": [args.model], "max_jobs": 1},
    )
    job = claimed_job(claim)

    if int(job.get("id") or job.get("job_id") or 0) != args.job_id:
        raise Refusal("REFUSE_CLAIMED_JOB_ID_MISMATCH")
    if str(job.get("status") or "") != "running":
        raise Refusal("REFUSE_CLAIMED_JOB_NOT_RUNNING")
    if str(job.get("job_type") or "") != "companion.chat":
        raise Refusal("REFUSE_NOT_COMPANION_CHAT")
    if str(job.get("requested_model") or "") != args.model:
        raise Refusal("REFUSE_REQUESTED_MODEL_MISMATCH")
    if args.expected_user_id and int(job.get("user_id") or 0) != args.expected_user_id:
        raise Refusal("REFUSE_USER_ID_MISMATCH")

    wrapped = wrap_prompt(str(job.get("prompt") or ""))
    raw = run_ollama(args.container, args.model, wrapped, args.timeout)
    validation = validate_visible_output(raw)
    if not validation["passed"]:
        post_json(
            args.base_url,
            f"/internal/edge-worker/jobs/{args.job_id}/fail",
            token,
            {"worker_id": args.worker_id, "error": "REFUSE_VISIBLE_OUTPUT_VALIDATION:" + ",".join(validation["flags"])},
        )
        raise Refusal("REFUSE_VISIBLE_OUTPUT_VALIDATION:" + ",".join(validation["flags"]))

    response_json = {
        "ok": True,
        "stage": "stage16-fc-o45-j",
        "mode": "one_real_companion_ollama_job",
        "model": args.model,
        "worker_id": args.worker_id,
        "validation": {"passed": True, "flags": []},
        "visible_output_sha256": validation["visible_output_sha256"],
        "model_endpoint_called": True,
        "ollama_called": True,
        "broad_queue_draining": False,
        "scheduler_timer_activation": False,
        "persistent_worker_activation": False,
    }
    complete = post_json(
        args.base_url,
        f"/internal/edge-worker/jobs/{args.job_id}/complete",
        token,
        {
            "worker_id": args.worker_id,
            "model": args.model,
            "response_text": validation["visible_output"],
            "response_json": response_json,
            "error": None,
        },
    )

    print(json.dumps({
        "ok": True,
        "stage": "stage16-fc-o45-j",
        "job_id": args.job_id,
        "model": args.model,
        "response_text": validation["visible_output"],
        "visible_output_sha256": validation["visible_output_sha256"],
        "complete_ok": complete.get("ok") is True,
    }, ensure_ascii=False, sort_keys=True, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Refusal as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(2)
