#!/usr/bin/env python3
"""
Stage 16 E3Z CT101 minimal Ollama worker skeleton.

Repository-only skeleton:
- Default-off.
- Safe to import and self-test without CT203, CT101, Docker, Ollama, or systemd access.
- Live loop is intentionally guarded by EDGE_WORKER_ENABLED=1 and not used by repo smoke.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Sequence, Tuple


class WorkerRefusal(RuntimeError):
    """Raised when the worker refuses to proceed for a safety reason."""


ANSI_RE = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")
OSC_RE = re.compile(r"\x1b\][^\x07]*(\x07|\x1b\\)")


@dataclass(frozen=True)
class WorkerConfig:
    worker_enabled: bool
    worker_id: str
    ct203_api_base: str
    token_file: str
    model_profile_file: str
    claim_policy: str
    max_jobs_per_loop: int
    strict_runtime_containment: bool
    allow_model_concurrency: bool
    allowed_container_names: Tuple[str, ...]


@dataclass(frozen=True)
class ModelProfile:
    profile_id: str
    model_name: str
    role: str
    endpoint_type: str
    container_name: str
    cli_flags: Tuple[str, ...]
    timeout_seconds: int
    max_concurrent_model_calls: int
    claim_policy: str
    exact_marker_supported: bool
    thinking_mode: str
    hidethinking_required: bool
    allowed_job_types: Tuple[str, ...]
    completion_validation_policy: str
    enabled_by_default: bool


def load_env(env: Optional[Dict[str, str]] = None) -> WorkerConfig:
    src = dict(os.environ if env is None else env)

    def truthy(name: str, default: str = "0") -> bool:
        return src.get(name, default).strip() == "1"

    allowed_raw = src.get("EDGE_ALLOWED_CONTAINER_NAMES", "ollama").strip()
    allowed = tuple(x.strip() for x in allowed_raw.split(",") if x.strip())

    max_jobs = int(src.get("EDGE_MAX_JOBS_PER_LOOP", "1"))
    if max_jobs != 1:
        raise WorkerRefusal("REFUSE_CONFIG_MAX_JOBS_NOT_ONE")

    return WorkerConfig(
        worker_enabled=truthy("EDGE_WORKER_ENABLED", "0"),
        worker_id=src.get("EDGE_WORKER_ID", "ct101-minimal-ollama-worker"),
        ct203_api_base=src.get("EDGE_CT203_API_BASE", "http://192.168.0.250:7070").rstrip("/"),
        token_file=src.get("EDGE_CT203_INTERNAL_QUEUE_TOKEN_FILE", "/opt/ai-platform/.secrets/laptop-queue.env"),
        model_profile_file=src.get("EDGE_MODEL_PROFILE_FILE", "ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml"),
        claim_policy=src.get("EDGE_CLAIM_POLICY", "one_at_a_time"),
        max_jobs_per_loop=max_jobs,
        strict_runtime_containment=truthy("EDGE_STRICT_RUNTIME_CONTAINMENT", "1"),
        allow_model_concurrency=truthy("EDGE_ALLOW_MODEL_CONCURRENCY", "0"),
        allowed_container_names=allowed,
    )


def load_token(token_file: str) -> str:
    token_path = Path(token_file)
    if not token_path.exists():
        raise WorkerRefusal("REFUSE_TOKEN_FILE_MISSING")

    token: Optional[str] = None
    for line in token_path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        value = value.strip().strip('"').strip("'")
        if "TOKEN" in key.upper() and value:
            token = value
            break

    if not token:
        raise WorkerRefusal("REFUSE_TOKEN_VALUE_MISSING")
    return token


def _import_yaml():
    try:
        import yaml  # type: ignore
    except Exception as exc:
        raise WorkerRefusal(f"REFUSE_PROFILE_YAML_IMPORT_FAILED:{exc!r}") from exc
    return yaml


def load_model_profiles(profile_file: str) -> Dict[str, ModelProfile]:
    yaml = _import_yaml()
    path = Path(profile_file)
    if not path.exists():
        raise WorkerRefusal("REFUSE_PROFILE_FILE_MISSING")

    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    validate_model_profile_document(data)

    profiles: Dict[str, ModelProfile] = {}
    for raw in data["profiles"]:
        profile = ModelProfile(
            profile_id=str(raw["profile_id"]),
            model_name=str(raw["model_name"]),
            role=str(raw["role"]),
            endpoint_type=str(raw["endpoint_type"]),
            container_name=str(raw["container_name"]),
            cli_flags=tuple(str(x) for x in raw.get("cli_flags", [])),
            timeout_seconds=int(raw["timeout_seconds"]),
            max_concurrent_model_calls=int(raw["max_concurrent_model_calls"]),
            claim_policy=str(raw["claim_policy"]),
            exact_marker_supported=bool(raw["exact_marker_supported"]),
            thinking_mode=str(raw["thinking_mode"]),
            hidethinking_required=bool(raw["hidethinking_required"]),
            allowed_job_types=tuple(str(x) for x in raw.get("allowed_job_types", [])),
            completion_validation_policy=str(raw["completion_validation_policy"]),
            enabled_by_default=bool(raw["enabled_by_default"]),
        )
        profiles[profile.profile_id] = profile
    return profiles


def validate_model_profile_document(data: Any) -> None:
    if not isinstance(data, dict):
        raise WorkerRefusal("REFUSE_PROFILE_INVALID_ROOT")
    if data.get("schema_version") != 1:
        raise WorkerRefusal("REFUSE_PROFILE_INVALID_SCHEMA_VERSION")
    if data.get("claim_policy_default") != "one_at_a_time":
        raise WorkerRefusal("REFUSE_PROFILE_INVALID_CLAIM_POLICY_DEFAULT")
    if data.get("enabled_by_default") is not False:
        raise WorkerRefusal("REFUSE_PROFILE_ARTIFACT_NOT_DISABLED_BY_DEFAULT")

    profiles = data.get("profiles")
    if not isinstance(profiles, list) or not profiles:
        raise WorkerRefusal("REFUSE_PROFILE_LIST_EMPTY")

    ids: set[str] = set()
    for raw in profiles:
        if not isinstance(raw, dict):
            raise WorkerRefusal("REFUSE_PROFILE_ENTRY_NOT_DICT")
        pid = str(raw.get("profile_id", ""))
        if not pid or pid in ids:
            raise WorkerRefusal("REFUSE_PROFILE_ID_DUPLICATE_OR_EMPTY")
        ids.add(pid)

        if raw.get("enabled_by_default") is not False:
            raise WorkerRefusal("REFUSE_PROFILE_ENABLED_BY_DEFAULT")
        if raw.get("claim_policy") != "one_at_a_time":
            raise WorkerRefusal("REFUSE_PROFILE_CLAIM_POLICY_NOT_ONE_AT_A_TIME")
        if int(raw.get("max_concurrent_model_calls", 0)) < 1:
            raise WorkerRefusal("REFUSE_PROFILE_BAD_MAX_CONCURRENT")
        if not raw.get("model_name"):
            raise WorkerRefusal("REFUSE_PROFILE_EMPTY_MODEL_NAME")
        if not raw.get("allowed_job_types"):
            raise WorkerRefusal("REFUSE_PROFILE_EMPTY_ALLOWED_JOB_TYPES")
        if raw.get("completion_validation_policy") == "no_default_until_proven" and raw.get("enabled_by_default") is True:
            raise WorkerRefusal("REFUSE_UNPROVEN_PROFILE_ENABLED")

    by_id = {str(p["profile_id"]): p for p in profiles}
    qwen3 = by_id.get("qwen3_router_small")
    if not qwen3:
        raise WorkerRefusal("REFUSE_QWEN3_PROFILE_MISSING")
    if qwen3.get("cli_flags") != ["--think=false", "--hidethinking"]:
        raise WorkerRefusal("REFUSE_QWEN3_FLAGS_INVALID")


def runtime_preflight(config: WorkerConfig, *, live: bool = False) -> None:
    if not config.worker_enabled:
        raise WorkerRefusal("REFUSE_WORKER_DISABLED")
    if config.claim_policy != "one_at_a_time":
        raise WorkerRefusal("REFUSE_CLAIM_POLICY_NOT_ONE_AT_A_TIME")
    if config.max_jobs_per_loop != 1:
        raise WorkerRefusal("REFUSE_MAX_JOBS_PER_LOOP_NOT_ONE")
    if config.allow_model_concurrency:
        raise WorkerRefusal("REFUSE_MODEL_CONCURRENCY_NOT_ENABLED_FOR_FIRST_WORKER")

    if not live:
        return

    if config.strict_runtime_containment:
        cmd = ["docker", "ps", "--format", "{{.Names}}"]
        proc = subprocess.run(cmd, text=True, capture_output=True, check=False)
        if proc.returncode != 0:
            raise WorkerRefusal("REFUSE_DOCKER_PS_FAILED")
        running = tuple(sorted(x.strip() for x in proc.stdout.splitlines() if x.strip()))
        if running != tuple(sorted(config.allowed_container_names)):
            raise WorkerRefusal("REFUSE_RUNTIME_CONTAINMENT")


def get_eligible_profile_for_job(job: Dict[str, Any], profiles: Dict[str, ModelProfile]) -> ModelProfile:
    requested_model = str(job.get("requested_model") or job.get("model") or "")
    job_type = str(job.get("job_type") or "")

    candidates = [p for p in profiles.values() if p.model_name == requested_model]
    if not candidates:
        raise WorkerRefusal("REFUSE_NO_PROFILE_FOR_MODEL")
    if len(candidates) > 1:
        raise WorkerRefusal("REFUSE_MULTIPLE_PROFILES_FOR_MODEL")

    profile = candidates[0]
    if job_type not in profile.allowed_job_types:
        raise WorkerRefusal("REFUSE_JOB_TYPE_NOT_ALLOWED_FOR_PROFILE")
    if profile.completion_validation_policy == "no_default_until_proven":
        raise WorkerRefusal("REFUSE_PROFILE_NOT_PROVEN")
    return profile


def build_ollama_command(profile: ModelProfile, prompt: str) -> List[str]:
    if profile.endpoint_type != "ollama_cli_in_container":
        raise WorkerRefusal("REFUSE_UNSUPPORTED_ENDPOINT_TYPE")
    cmd = ["docker", "exec", profile.container_name, "ollama", "run"]
    cmd.extend(profile.cli_flags)
    cmd.append(profile.model_name)
    cmd.append(prompt)

    joined = " ".join(cmd)
    if "--think false" in joined:
        raise WorkerRefusal("REFUSE_QWEN3_BAD_THINK_SYNTAX")
    return cmd


def clean_model_output(stdout: str) -> str:
    clean = ANSI_RE.sub("", stdout or "")
    clean = OSC_RE.sub("", clean)
    clean = clean.replace("\r", "\n")
    lines = [line.strip() for line in clean.splitlines() if line.strip()]
    return "\n".join(lines).strip()


def extract_expected_marker(job: Dict[str, Any]) -> str:
    response_json = job.get("response_json")
    if isinstance(response_json, dict) and response_json.get("expected_marker"):
        return str(response_json["expected_marker"]).strip()

    prompt = str(job.get("prompt") or "")
    # Current proof prompt wording: "... nothing else: MARKER"
    match = re.search(r"nothing else:\s*([A-Za-z0-9_.:-]+)\s*$", prompt)
    if not match:
        raise WorkerRefusal("REFUSE_EXPECTED_MARKER_NOT_FOUND")
    return match.group(1)


def validate_completion(profile: ModelProfile, job: Dict[str, Any], response_text: str) -> str:
    if profile.completion_validation_policy != "exact_marker_only":
        raise WorkerRefusal("REFUSE_UNSUPPORTED_COMPLETION_VALIDATION")
    expected = extract_expected_marker(job)
    if response_text != expected:
        raise WorkerRefusal("REFUSE_MODEL_OUTPUT_NOT_EXACT")
    return expected


def _post_json(config: WorkerConfig, token: str, path: str, payload: Dict[str, Any]) -> Tuple[int, Dict[str, Any]]:
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        config.ct203_api_base + path,
        data=data,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "X-Laptop-Queue-Token": token,
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            body = resp.read().decode("utf-8", "replace")
            return resp.status, json.loads(body) if body else {}
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", "replace")
        return exc.code, {"error": body}


def _extract_claimed_job(claim_response: Dict[str, Any]) -> Dict[str, Any]:
    claimed = claim_response.get("claimed")
    if isinstance(claimed, dict):
        return claimed
    if isinstance(claimed, list):
        if len(claimed) != 1:
            raise WorkerRefusal("REFUSE_CLAIM_INVARIANT_MULTIPLE")
        return claimed[0]
    jobs = claim_response.get("jobs")
    if isinstance(jobs, list):
        if len(jobs) != 1:
            raise WorkerRefusal("REFUSE_CLAIM_INVARIANT_MULTIPLE")
        return jobs[0]
    job = claim_response.get("job")
    if isinstance(job, dict):
        return job
    raise WorkerRefusal("REFUSE_CLAIM_INVARIANT_NO_JOB")


def claim_one_job(config: WorkerConfig, token: str, job_id: int) -> Dict[str, Any]:
    status, body = _post_json(
        config,
        token,
        "/internal/edge-worker/jobs/claim",
        {"worker_id": config.worker_id, "claim_job_ids": [job_id], "max_jobs": 1},
    )
    if status != 200:
        raise WorkerRefusal("REFUSE_CLAIM_HTTP_NOT_200")

    job = _extract_claimed_job(body)
    cid = int(job.get("id") or job.get("job_id") or 0)
    if cid != job_id:
        raise WorkerRefusal("REFUSE_CLAIM_INVARIANT_WRONG_JOB")
    if str(job.get("status") or "") != "running":
        raise WorkerRefusal("REFUSE_CLAIM_INVARIANT_NOT_RUNNING")
    if int(job.get("attempts") or 0) < 1:
        raise WorkerRefusal("REFUSE_CLAIM_INVARIANT_ATTEMPTS")
    return job


def run_ollama_call(profile: ModelProfile, prompt: str) -> str:
    cmd = build_ollama_command(profile, prompt)
    proc = subprocess.run(cmd, text=True, capture_output=True, timeout=profile.timeout_seconds, check=False)
    if proc.returncode != 0:
        raise WorkerRefusal("REFUSE_MODEL_CALL_FAILED")
    response = clean_model_output(proc.stdout)
    if not response:
        raise WorkerRefusal("REFUSE_MODEL_CALL_EMPTY")
    return response


def complete_job(config: WorkerConfig, token: str, job_id: int, profile: ModelProfile, response_text: str) -> None:
    status, _body = _post_json(
        config,
        token,
        f"/internal/edge-worker/jobs/{job_id}/complete",
        {
            "worker_id": config.worker_id,
            "model": profile.model_name,
            "response_text": response_text,
            "response_json": {
                "stage": "stage-16-e3z-cs-skeleton",
                "profile_id": profile.profile_id,
                "exact_match": True,
            },
        },
    )
    if status != 200:
        raise WorkerRefusal("REFUSE_COMPLETE_HTTP_NOT_200")


def main_once(config: WorkerConfig, *, job_id: Optional[int] = None, live: bool = False) -> int:
    runtime_preflight(config, live=live)
    profiles = load_model_profiles(config.model_profile_file)
    token = load_token(config.token_file)

    if job_id is None:
        raise WorkerRefusal("REFUSE_NO_JOB_ID_FOR_SKELETON_ONCE")

    claimed = claim_one_job(config, token, job_id)
    profile = get_eligible_profile_for_job(claimed, profiles)
    response = run_ollama_call(profile, str(claimed.get("prompt") or ""))
    validate_completion(profile, claimed, response)
    complete_job(config, token, job_id, profile, response)
    return 0


def main_loop(config: WorkerConfig) -> int:
    # A real polling loop is intentionally not implemented in this skeleton.
    raise WorkerRefusal("REFUSE_MAIN_LOOP_NOT_IMPLEMENTED_IN_REPO_SKELETON")


def _self_test(profile_path: str) -> int:
    profiles = load_model_profiles(profile_path)

    q25 = profiles["qwen25_router_small"]
    q3 = profiles["qwen3_router_small"]

    cmd25 = build_ollama_command(q25, "PROMPT")
    assert cmd25 == ["docker", "exec", "ollama", "ollama", "run", "qwen2.5:0.5b", "PROMPT"]

    cmd3 = build_ollama_command(q3, "PROMPT")
    assert cmd3 == [
        "docker",
        "exec",
        "ollama",
        "ollama",
        "run",
        "--think=false",
        "--hidethinking",
        "qwen3:0.6b",
        "PROMPT",
    ]
    assert "--think false" not in " ".join(cmd3)

    noisy = "\x1b[?25l\rE3Z-CON-QWEN3-A-OK\n\x1b[?25h"
    assert clean_model_output(noisy) == "E3Z-CON-QWEN3-A-OK"

    job = {
        "requested_model": "qwen3:0.6b",
        "job_type": "stage16_e3z_cj_concurrency_model_proof",
        "prompt": "Stage 16. Return exactly this text and nothing else: E3Z-CON-QWEN3-A-OK",
    }
    selected = get_eligible_profile_for_job(job, profiles)
    assert selected.profile_id == "qwen3_router_small"
    assert extract_expected_marker(job) == "E3Z-CON-QWEN3-A-OK"
    assert validate_completion(selected, job, "E3Z-CON-QWEN3-A-OK") == "E3Z-CON-QWEN3-A-OK"

    try:
        validate_completion(selected, job, "wrong")
    except WorkerRefusal as exc:
        assert "REFUSE_MODEL_OUTPUT_NOT_EXACT" in str(exc)
    else:
        raise AssertionError("non-exact output did not refuse")

    disabled_config = load_env({"EDGE_WORKER_ENABLED": "0", "EDGE_MAX_JOBS_PER_LOOP": "1"})
    try:
        runtime_preflight(disabled_config, live=False)
    except WorkerRefusal as exc:
        assert "REFUSE_WORKER_DISABLED" in str(exc)
    else:
        raise AssertionError("disabled worker did not refuse")

    print("E3Z_CS_WORKER_SELF_TEST_OK=1")
    return 0


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Stage 16 E3Z CT101 minimal Ollama worker skeleton")
    parser.add_argument("--self-test", action="store_true", help="run repo-only self tests")
    parser.add_argument("--profile-file", default="ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml")
    parser.add_argument("--once", action="store_true", help="run one live job; guarded by EDGE_WORKER_ENABLED=1")
    parser.add_argument("--loop", action="store_true", help="run live loop; not implemented in repo skeleton")
    parser.add_argument("--job-id", type=int, default=None)
    args = parser.parse_args(argv)

    if args.self_test:
        return _self_test(args.profile_file)

    config = load_env()
    if args.once:
        return main_once(config, job_id=args.job_id, live=True)
    if args.loop:
        return main_loop(config)

    print("REFUSE_NO_MODE_SELECTED")
    return 2


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except WorkerRefusal as exc:
        print(str(exc))
        raise SystemExit(1)
