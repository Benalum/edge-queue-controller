#!/usr/bin/env python3
"""Stage 16 E3Z CT101 minimal Ollama worker.

This worker is intentionally conservative. It supports:
- self tests that do not touch live systems
- an exact one-shot mode for a specified job id
- a limited persistent one-job proof mode guarded by explicit allowlist/exit/runtime settings

It refuses by default unless EDGE_WORKER_ENABLED=1.
"""

from __future__ import annotations

import argparse
import hashlib
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
from typing import Any, Dict, List, Optional, Sequence, Tuple


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
    proof_mode: str
    allowed_job_ids: Tuple[int, ...]
    exit_after_one_success: bool
    max_runtime_seconds: Optional[int]
    refuse_if_scheduler_active: bool
    refuse_if_timer_active: bool


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


def parse_bool(value: str, *, default: bool = False) -> bool:
    raw = str(value).strip().lower()
    if raw == "":
        return default
    if raw in {"1", "true", "yes", "on"}:
        return True
    if raw in {"0", "false", "no", "off"}:
        return False
    raise WorkerRefusal("REFUSE_WORKER_BOOL_INVALID")


def parse_allowed_job_ids(value: str) -> Tuple[int, ...]:
    raw = str(value or "").strip()
    if not raw:
        return tuple()
    ids: List[int] = []
    for part in raw.split(","):
        item = part.strip()
        if not item or not re.fullmatch(r"[0-9]+", item):
            raise WorkerRefusal("REFUSE_WORKER_ALLOWED_JOB_IDS_INVALID")
        parsed = int(item)
        if parsed <= 0:
            raise WorkerRefusal("REFUSE_WORKER_ALLOWED_JOB_IDS_INVALID")
        ids.append(parsed)
    if len(set(ids)) != len(ids):
        raise WorkerRefusal("REFUSE_WORKER_ALLOWED_JOB_IDS_INVALID")
    return tuple(ids)


def parse_optional_positive_int(value: Optional[str], marker: str) -> Optional[int]:
    if value is None or str(value).strip() == "":
        return None
    raw = str(value).strip()
    if not re.fullmatch(r"[0-9]+", raw):
        raise WorkerRefusal(marker)
    parsed = int(raw)
    if parsed <= 0:
        raise WorkerRefusal(marker)
    return parsed


def load_env(env: Optional[Dict[str, str]] = None) -> WorkerConfig:
    src = dict(os.environ if env is None else env)

    allowed_raw = src.get("EDGE_ALLOWED_CONTAINER_NAMES", "ollama").strip()
    allowed = tuple(x.strip() for x in allowed_raw.split(",") if x.strip())

    try:
        max_jobs = int(src.get("EDGE_MAX_JOBS_PER_LOOP", "1"))
    except ValueError as exc:
        raise WorkerRefusal("REFUSE_CONFIG_MAX_JOBS_NOT_ONE") from exc
    if max_jobs != 1:
        raise WorkerRefusal("REFUSE_CONFIG_MAX_JOBS_NOT_ONE")

    allowed_job_ids = parse_allowed_job_ids(src.get("EDGE_ALLOWED_JOB_IDS", ""))
    max_runtime_seconds = parse_optional_positive_int(
        src.get("EDGE_MAX_RUNTIME_SECONDS"),
        "REFUSE_WORKER_MAX_RUNTIME_SECONDS_INVALID",
    )

    return WorkerConfig(
        worker_enabled=parse_bool(src.get("EDGE_WORKER_ENABLED", "0"), default=False),
        worker_id=src.get("EDGE_WORKER_ID", "ct101-minimal-ollama-worker"),
        ct203_api_base=src.get("EDGE_CT203_API_BASE", "http://192.168.0.250:7070").rstrip("/"),
        token_file=src.get("EDGE_CT203_INTERNAL_QUEUE_TOKEN_FILE", "/opt/ai-platform/.secrets/laptop-queue.env"),
        model_profile_file=src.get("EDGE_MODEL_PROFILE_FILE", "ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml"),
        claim_policy=src.get("EDGE_CLAIM_POLICY", "one_at_a_time"),
        max_jobs_per_loop=max_jobs,
        strict_runtime_containment=parse_bool(src.get("EDGE_STRICT_RUNTIME_CONTAINMENT", "1"), default=True),
        allow_model_concurrency=parse_bool(src.get("EDGE_ALLOW_MODEL_CONCURRENCY", "0"), default=False),
        allowed_container_names=allowed,
        proof_mode=src.get("EDGE_PROOF_MODE", "").strip(),
        allowed_job_ids=allowed_job_ids,
        exit_after_one_success=parse_bool(src.get("EDGE_EXIT_AFTER_ONE_SUCCESS", "0"), default=False),
        max_runtime_seconds=max_runtime_seconds,
        refuse_if_scheduler_active=parse_bool(src.get("EDGE_REFUSE_IF_SCHEDULER_ACTIVE", "1"), default=True),
        refuse_if_timer_active=parse_bool(src.get("EDGE_REFUSE_IF_TIMER_ACTIVE", "1"), default=True),
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


def validate_allowed_job_id(config: WorkerConfig, job_id: int) -> None:
    if config.allowed_job_ids and tuple(config.allowed_job_ids) != (job_id,):
        raise WorkerRefusal("REFUSE_WORKER_CLAIMED_JOB_ID_NOT_ALLOWED")


def validate_limited_proof_mode(config: WorkerConfig, *, job_id: Optional[int] = None) -> int:
    if config.proof_mode != "limited_persistent_one_job":
        raise WorkerRefusal("REFUSE_WORKER_PROOF_MODE_GUARD_FAILED")
    if config.allow_model_concurrency:
        raise WorkerRefusal("REFUSE_MODEL_CONCURRENCY_NOT_ENABLED_FOR_FIRST_WORKER")
    if len(config.allowed_job_ids) == 0:
        raise WorkerRefusal("REFUSE_WORKER_EXACT_JOB_CLAIM_REQUIRED")
    if len(config.allowed_job_ids) != 1:
        raise WorkerRefusal("REFUSE_WORKER_ALLOWED_JOB_IDS_INVALID")
    allowed_id = config.allowed_job_ids[0]
    if job_id is not None and job_id != allowed_id:
        raise WorkerRefusal("REFUSE_WORKER_CLAIMED_JOB_ID_NOT_ALLOWED")
    if not config.exit_after_one_success:
        raise WorkerRefusal("REFUSE_WORKER_EXIT_AFTER_ONE_SUCCESS_REQUIRED")
    if not config.max_runtime_seconds:
        raise WorkerRefusal("REFUSE_WORKER_MAX_RUNTIME_SECONDS_INVALID")
    if not config.refuse_if_scheduler_active:
        raise WorkerRefusal("REFUSE_WORKER_PROOF_MODE_GUARD_FAILED")
    if not config.refuse_if_timer_active:
        raise WorkerRefusal("REFUSE_WORKER_PROOF_MODE_GUARD_FAILED")
    return allowed_id


def _active_systemd_lines() -> str:
    proc = subprocess.run(["systemctl", "list-units", "--state=active", "--no-legend"], text=True, capture_output=True, check=False)
    if proc.returncode != 0:
        return ""
    return proc.stdout


def _active_timer_lines() -> str:
    proc = subprocess.run(["systemctl", "list-timers", "--all", "--no-legend"], text=True, capture_output=True, check=False)
    if proc.returncode != 0:
        return ""
    return proc.stdout


def guard_scheduler_timer_inactive(config: WorkerConfig) -> None:
    if config.refuse_if_scheduler_active:
        active_units = _active_systemd_lines().lower()
        for line in active_units.splitlines():
            if ("edge" in line or "queue" in line or "worker" in line) and "scheduler" in line:
                raise WorkerRefusal("REFUSE_WORKER_SCHEDULER_ACTIVE")
    if config.refuse_if_timer_active:
        active_timers = _active_timer_lines().lower()
        for line in active_timers.splitlines():
            if ("edge" in line or "queue" in line or "worker" in line or "scheduler" in line) and ".timer" in line:
                raise WorkerRefusal("REFUSE_WORKER_TIMER_ACTIVE")


def runtime_preflight(config: WorkerConfig, *, live: bool = False, job_id: Optional[int] = None, loop: bool = False) -> None:
    if not config.worker_enabled:
        raise WorkerRefusal("REFUSE_WORKER_DISABLED")
    if config.claim_policy != "one_at_a_time":
        raise WorkerRefusal("REFUSE_CLAIM_POLICY_NOT_ONE_AT_A_TIME")
    if config.max_jobs_per_loop != 1:
        raise WorkerRefusal("REFUSE_MAX_JOBS_PER_LOOP_NOT_ONE")
    if config.allow_model_concurrency:
        raise WorkerRefusal("REFUSE_MODEL_CONCURRENCY_NOT_ENABLED_FOR_FIRST_WORKER")

    if config.proof_mode:
        validate_limited_proof_mode(config, job_id=job_id)
    elif loop:
        raise WorkerRefusal("REFUSE_MAIN_LOOP_REQUIRES_LIMITED_PROOF_MODE")
    elif config.allowed_job_ids and job_id is not None:
        validate_allowed_job_id(config, job_id)

    if not live:
        return

    if config.proof_mode:
        guard_scheduler_timer_inactive(config)

    if config.strict_runtime_containment:
        proc = subprocess.run(["docker", "ps", "--format", "{{.Names}}"], text=True, capture_output=True, check=False)
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
    match = re.search(r"nothing else:\s*([A-Za-z0-9_.:-]+)\s*$", prompt)
    if not match:
        raise WorkerRefusal("REFUSE_EXPECTED_MARKER_NOT_FOUND")
    return match.group(1)


def validate_completion(profile: ModelProfile, job: Dict[str, Any], response_text: str) -> str:
    # Stage 16 FB-R4: explicit worker mode split.
    # Default remains exact-marker proof behavior. general_queue skips
    # marker extraction but still enforces bounded, non-empty model output.
    _stage16_worker_mode = os.environ.get("EDGE_WORKER_MODE", "exact_marker").strip().lower()
    if _stage16_worker_mode in ("", "exact", "strict"):
        _stage16_worker_mode = "exact_marker"
    if _stage16_worker_mode not in ("exact_marker", "general_queue"):
        raise WorkerRefusal(f"REFUSE_UNKNOWN_WORKER_MODE:{_stage16_worker_mode}")
    if _stage16_worker_mode == "general_queue":
        _stage16_completion_text = None
        for _stage16_name in (
            "completion",
            "completion_text",
            "response",
            "response_text",
            "output",
            "cleaned_output",
            "text",
        ):
            if _stage16_name in locals():
                _stage16_completion_text = locals()[_stage16_name]
                break
        if _stage16_completion_text is None:
            _stage16_local_values = list(locals().values())
            if _stage16_local_values:
                _stage16_completion_text = _stage16_local_values[-1]
        _stage16_completion_text = "" if _stage16_completion_text is None else str(_stage16_completion_text)
        try:
            _stage16_max_response_chars = int(os.environ.get("EDGE_GENERAL_QUEUE_MAX_RESPONSE_CHARS", "12000"))
        except ValueError:
            raise WorkerRefusal("REFUSE_GENERAL_QUEUE_INVALID_MAX_RESPONSE_CHARS")
        if _stage16_max_response_chars <= 0:
            raise WorkerRefusal("REFUSE_GENERAL_QUEUE_INVALID_MAX_RESPONSE_CHARS")
        if not _stage16_completion_text.strip():
            raise WorkerRefusal("REFUSE_GENERAL_QUEUE_EMPTY_RESPONSE")
        if len(_stage16_completion_text) > _stage16_max_response_chars:
            raise WorkerRefusal("REFUSE_GENERAL_QUEUE_RESPONSE_TOO_LARGE")
        return
    if profile.completion_validation_policy != "exact_marker_only":
        raise WorkerRefusal("REFUSE_UNSUPPORTED_COMPLETION_VALIDATION")
    expected = extract_expected_marker(job)
    if response_text != expected:
        raise WorkerRefusal("REFUSE_WORKER_EXACT_MARKER_MISMATCH")
    return expected



@dataclass(frozen=True)
class ProductValidationResult:
    passed: bool
    visible_output: str
    refusal_code: str
    reasons: Tuple[str, ...]
    raw_output_sha256: str
    visible_output_sha256: str
    result_contract: str = "product_visible_output_v1"


def _sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def extract_visible_output(raw_output: str) -> str:
    return (raw_output or "").replace("\r\n", "\n").replace("\r", "\n").strip()


def detect_visible_thinking(text: str) -> bool:
    lowered = (text or "").lower()
    patterns = (
        r"\bthinking\.\.\.",
        r"\bthinking process\b",
        r"\banalyze the request\b",
        r"\bdetermine constraints\b",
        r"\bconstraints checklist\b",
        r"\bstep\s+1\s*:",
        r"\bstep\s+2\s*:",
        r"\bi am thinking\b",
        r"\blet'?s think\b",
        r"\bwe need answer\b",
        r"\bthe user wants\b",
    )
    return any(re.search(pattern, lowered) for pattern in patterns)


def detect_hidden_thinking_markers(text: str) -> bool:
    lowered = (text or "").lower()
    return any(marker in lowered for marker in ("<think>", "</think>", "<thinking>", "</thinking>"))


def _parse_json_object(text: str) -> Any:
    try:
        return json.loads((text or "").strip())
    except Exception:
        return None


def detect_guard_metadata_output(text: str) -> bool:
    raw = (text or "").strip()
    lowered = raw.lower()
    parsed = _parse_json_object(raw)
    if isinstance(parsed, dict):
        if parsed.get("exact_match") is True:
            return True
        if parsed.get("stage") == "stage-16-e3z-ec-worker-guards":
            return True
        if set(parsed.keys()).issubset({"exact_match", "profile_id", "stage"}):
            return True
    return any(term in lowered for term in ("stage-16-e3z-ec-worker-guards", "exact_match", "refuse_worker_exact_marker_mismatch"))


def detect_internal_surface_terms(text: str, job_type: str = "") -> bool:
    lowered = (text or "").lower()
    parsed = _parse_json_object(text)
    if job_type == "stage16_fc_flashcards_semantic_probe" and parsed is not None:
        terms = ("queue", "worker", "system", "instruction", "job_results", "response_json", "response_text", "exact marker")
    else:
        terms = ("prompt", "queue", "worker", "system", "instruction", "job id", "job_results", "response_json", "response_text", "exact marker")
    return any(term in lowered for term in terms)


def _fail_product(raw_output: str, visible_output: str, code: str, reasons: Tuple[str, ...]) -> ProductValidationResult:
    return ProductValidationResult(False, visible_output, code, reasons, _sha256_text(raw_output or ""), _sha256_text(visible_output or ""))


def _pass_product(raw_output: str, visible_output: str) -> ProductValidationResult:
    return ProductValidationResult(True, visible_output, "", (), _sha256_text(raw_output or ""), _sha256_text(visible_output or ""))


def validate_product_visible_output(profile: ModelProfile, job: Dict[str, Any], raw_output: str) -> ProductValidationResult:
    job_type = str(job.get("job_type") or "")
    prompt = str(job.get("prompt") or "")
    visible_output = extract_visible_output(raw_output)

    if not visible_output:
        return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_EMPTY_VISIBLE_OUTPUT", ("empty_visible_output",))
    if detect_hidden_thinking_markers(visible_output):
        return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_HIDDEN_THINKING", ("hidden_thinking_markers_present",))
    if detect_visible_thinking(visible_output):
        return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_VISIBLE_THINKING", ("visible_thinking_present",))
    if detect_guard_metadata_output(visible_output):
        return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_GUARD_JSON", ("guard_metadata_output",))

    if job_type == "stage16_fc_companion_chat_semantic_probe":
        lowered = visible_output.lower()
        if _parse_json_object(visible_output) is not None:
            return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_SHAPE_MISMATCH", ("companion_output_must_not_be_json",))
        if len(visible_output) < 40:
            return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_SHAPE_MISMATCH", ("companion_output_too_short",))
        if not re.search(r"\b(you|your)\b", lowered):
            return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_SHAPE_MISMATCH", ("companion_direct_address_missing",))
        if "i am an ai" in lowered or "i'm an ai" in lowered:
            return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_INTERNAL_TERMS", ("companion_ai_self_reference",))
        if detect_internal_surface_terms(visible_output, job_type):
            return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_INTERNAL_TERMS", ("internal_surface_terms_present",))
        return _pass_product(raw_output, visible_output)

    if job_type == "stage16_fc_study_tutor_semantic_probe":
        if detect_internal_surface_terms(visible_output, job_type):
            return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_INTERNAL_TERMS", ("internal_surface_terms_present",))
        if "bullet" in prompt.lower():
            lines = [line.strip() for line in visible_output.splitlines() if line.strip()]
            if not lines or not all(line.startswith("- ") for line in lines):
                return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_SHAPE_MISMATCH", ("study_bullet_shape_mismatch",))
        return _pass_product(raw_output, visible_output)

    if job_type == "stage16_fc_flashcards_semantic_probe":
        parsed = _parse_json_object(visible_output)
        if parsed is None:
            return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_SHAPE_MISMATCH", ("flashcards_json_parse_failed",))
        if not isinstance(parsed, list):
            return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_SHAPE_MISMATCH", ("flashcards_json_not_list",))
        for item in parsed:
            if not isinstance(item, dict) or "prompt" not in item or "answer" not in item:
                return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_SHAPE_MISMATCH", ("flashcards_prompt_answer_schema_missing",))
        return _pass_product(raw_output, visible_output)

    if job_type == "stage16_fc_safe_refusal_semantic_probe":
        lowered = visible_output.lower()
        if detect_internal_surface_terms(visible_output, job_type):
            return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_INTERNAL_TERMS", ("internal_surface_terms_present",))
        if "private credential" not in lowered:
            return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_SHAPE_MISMATCH", ("safe_refusal_required_term_missing",))
        if not any(term in lowered for term in ("can't", "cannot", "can’t", "won't", "will not", "unable", "not able")):
            return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_SHAPE_MISMATCH", ("safe_refusal_refusal_language_missing",))
        return _pass_product(raw_output, visible_output)

    return _fail_product(raw_output, visible_output, "REFUSE_PRODUCT_UNSUPPORTED_JOB_TYPE", ("unsupported_product_job_type",))


def build_product_response_json(profile: ModelProfile, job: Dict[str, Any], result: ProductValidationResult) -> Dict[str, Any]:
    return {
        "result_contract": "product_visible_output_v1",
        "profile_id": profile.profile_id,
        "model": profile.model_name,
        "job_type": str(job.get("job_type") or ""),
        "validation": {
            "passed": result.passed,
            "visible_thinking_absent": not detect_visible_thinking(result.visible_output),
            "hidden_thinking_markers_absent": not detect_hidden_thinking_markers(result.visible_output),
            "guard_metadata_absent_from_visible_output": not detect_guard_metadata_output(result.visible_output),
            "shape_valid": result.passed,
        },
        "raw_output_sha256": result.raw_output_sha256,
        "visible_output_sha256": result.visible_output_sha256,
    }


def build_completion_payload(profile: ModelProfile, job: Dict[str, Any], response_text: str) -> Dict[str, Any]:
    if profile.completion_validation_policy == "product_visible_output_v1":
        product_validation = validate_product_visible_output(profile, job, response_text)
        if not product_validation.passed:
            raise WorkerRefusal(product_validation.refusal_code)
        return {
            "model": profile.model_name,
            "response_text": product_validation.visible_output,
            "response_json": build_product_response_json(profile, job, product_validation),
        }

    return {
        "model": profile.model_name,
        "response_text": response_text,
        "response_json": {
            "stage": "stage-16-e3z-ec-worker-guards",
            "profile_id": profile.profile_id,
            "exact_match": True,
        },
    }



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
    validate_allowed_job_id(config, job_id)
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
        raise WorkerRefusal("REFUSE_CLAIMED_JOB_ID_NOT_ALLOWED")
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
    validate_allowed_job_id(config, job_id)
    status, _body = _post_json(
        config,
        token,
        f"/internal/edge-worker/jobs/{job_id}/complete",
        {
            "worker_id": config.worker_id,
            **build_completion_payload(profile, job, response_text),
        },
    )
    if status != 200:
        raise WorkerRefusal("REFUSE_COMPLETE_HTTP_NOT_200")


def run_one_claim_complete(config: WorkerConfig, profiles: Dict[str, ModelProfile], token: str, job_id: int) -> int:
    claimed = claim_one_job(config, token, job_id)
    profile = get_eligible_profile_for_job(claimed, profiles)
    response = run_ollama_call(profile, str(claimed.get("prompt") or ""))
    validate_completion(profile, claimed, response)
    complete_job(config, token, job_id, profile, response)
    return 0


def main_once(config: WorkerConfig, *, job_id: Optional[int] = None, live: bool = False) -> int:
    if job_id is None:
        raise WorkerRefusal("REFUSE_NO_JOB_ID_FOR_SKELETON_ONCE")
    runtime_preflight(config, live=live, job_id=job_id)
    profiles = load_model_profiles(config.model_profile_file)
    token = load_token(config.token_file)
    return run_one_claim_complete(config, profiles, token, job_id)


def main_loop(config: WorkerConfig) -> int:
    allowed_job_id = validate_limited_proof_mode(config)
    runtime_preflight(config, live=True, job_id=allowed_job_id, loop=True)
    profiles = load_model_profiles(config.model_profile_file)
    token = load_token(config.token_file)

    started = time.monotonic()
    claimed_count = 0
    completed_count = 0
    failed_count = 0
    last_claimed_job_id: Optional[int] = None
    last_completed_job_id: Optional[int] = None

    while True:
        elapsed = time.monotonic() - started
        if config.max_runtime_seconds is not None and elapsed > config.max_runtime_seconds:
            raise WorkerRefusal("REFUSE_WORKER_MAX_RUNTIME_SECONDS_EXCEEDED")

        try:
            claimed = claim_one_job(config, token, allowed_job_id)
            claimed_count += 1
            last_claimed_job_id = int(claimed.get("id") or claimed.get("job_id") or 0)
            if claimed_count > 1:
                raise WorkerRefusal("REFUSE_WORKER_MULTIPLE_JOBS_CLAIMED_IN_PROOF_MODE")

            profile = get_eligible_profile_for_job(claimed, profiles)
            response = run_ollama_call(profile, str(claimed.get("prompt") or ""))
            validate_completion(profile, claimed, response)
            complete_job(config, token, allowed_job_id, profile, response)
            completed_count += 1
            last_completed_job_id = allowed_job_id

            if (
                claimed_count == 1
                and completed_count == 1
                and failed_count == 0
                and last_claimed_job_id == allowed_job_id
                and last_completed_job_id == allowed_job_id
            ):
                print("E3Z_WORKER_LIMITED_PERSISTENT_ONE_JOB_SUCCESS=1")
                return 0
            raise WorkerRefusal("REFUSE_WORKER_PROOF_MODE_GUARD_FAILED")
        except WorkerRefusal:
            failed_count += 1
            raise


def _expect_refusal(marker: str, func, *args, **kwargs) -> None:
    try:
        func(*args, **kwargs)
    except WorkerRefusal as exc:
        assert marker in str(exc), (marker, str(exc))
        return
    raise AssertionError(f"{marker} did not refuse")


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

    _expect_refusal("REFUSE_WORKER_EXACT_MARKER_MISMATCH", validate_completion, selected, job, "wrong")

    disabled_config = load_env({"EDGE_WORKER_ENABLED": "0", "EDGE_MAX_JOBS_PER_LOOP": "1"})
    _expect_refusal("REFUSE_WORKER_DISABLED", runtime_preflight, disabled_config, live=False)

    assert parse_allowed_job_ids("47") == (47,)
    assert parse_allowed_job_ids("47,48") == (47, 48)
    _expect_refusal("REFUSE_WORKER_ALLOWED_JOB_IDS_INVALID", parse_allowed_job_ids, "abc")
    _expect_refusal("REFUSE_WORKER_ALLOWED_JOB_IDS_INVALID", parse_allowed_job_ids, "47,47")
    _expect_refusal("REFUSE_WORKER_MAX_RUNTIME_SECONDS_INVALID", parse_optional_positive_int, "0", "REFUSE_WORKER_MAX_RUNTIME_SECONDS_INVALID")

    base_env = {
        "EDGE_WORKER_ENABLED": "1",
        "EDGE_MAX_JOBS_PER_LOOP": "1",
        "EDGE_CLAIM_POLICY": "one_at_a_time",
        "EDGE_ALLOW_MODEL_CONCURRENCY": "0",
        "EDGE_PROOF_MODE": "limited_persistent_one_job",
        "EDGE_ALLOWED_JOB_IDS": "47",
        "EDGE_EXIT_AFTER_ONE_SUCCESS": "1",
        "EDGE_MAX_RUNTIME_SECONDS": "180",
        "EDGE_REFUSE_IF_SCHEDULER_ACTIVE": "1",
        "EDGE_REFUSE_IF_TIMER_ACTIVE": "1",
    }
    proof_config = load_env(base_env)
    assert validate_limited_proof_mode(proof_config) == 47
    validate_limited_proof_mode(proof_config, job_id=47)
    validate_allowed_job_id(proof_config, 47)
    _expect_refusal("REFUSE_WORKER_CLAIMED_JOB_ID_NOT_ALLOWED", validate_allowed_job_id, proof_config, 48)

    env_multi = dict(base_env, EDGE_ALLOWED_JOB_IDS="47,48")
    _expect_refusal("REFUSE_WORKER_ALLOWED_JOB_IDS_INVALID", validate_limited_proof_mode, load_env(env_multi))

    env_no_exit = dict(base_env, EDGE_EXIT_AFTER_ONE_SUCCESS="0")
    _expect_refusal("REFUSE_WORKER_EXIT_AFTER_ONE_SUCCESS_REQUIRED", validate_limited_proof_mode, load_env(env_no_exit))

    env_no_runtime = dict(base_env)
    env_no_runtime.pop("EDGE_MAX_RUNTIME_SECONDS")
    _expect_refusal("REFUSE_WORKER_MAX_RUNTIME_SECONDS_INVALID", validate_limited_proof_mode, load_env(env_no_runtime))

    env_concurrent = dict(base_env, EDGE_ALLOW_MODEL_CONCURRENCY="1")
    _expect_refusal("REFUSE_MODEL_CONCURRENCY_NOT_ENABLED_FOR_FIRST_WORKER", validate_limited_proof_mode, load_env(env_concurrent))

    env_no_allowed = dict(base_env, EDGE_ALLOWED_JOB_IDS="")
    _expect_refusal("REFUSE_WORKER_EXACT_JOB_CLAIM_REQUIRED", validate_limited_proof_mode, load_env(env_no_allowed))

    once_config = load_env({
        "EDGE_WORKER_ENABLED": "1",
        "EDGE_MAX_JOBS_PER_LOOP": "1",
        "EDGE_CLAIM_POLICY": "one_at_a_time",
        "EDGE_ALLOW_MODEL_CONCURRENCY": "0",
        "EDGE_ALLOWED_JOB_IDS": "47",
    })
    runtime_preflight(once_config, live=False, job_id=47)
    _expect_refusal("REFUSE_WORKER_CLAIMED_JOB_ID_NOT_ALLOWED", runtime_preflight, once_config, live=False, job_id=48)

    loop_config = load_env({
        "EDGE_WORKER_ENABLED": "1",
        "EDGE_MAX_JOBS_PER_LOOP": "1",
        "EDGE_CLAIM_POLICY": "one_at_a_time",
        "EDGE_ALLOW_MODEL_CONCURRENCY": "0",
    })
    _expect_refusal("REFUSE_MAIN_LOOP_REQUIRES_LIMITED_PROOF_MODE", runtime_preflight, loop_config, live=False, loop=True)

    print("E3Z_EC_WORKER_GUARD_SELF_TEST_OK=1")
    print("E3Z_CS_WORKER_SELF_TEST_OK=1")
    return 0


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Stage 16 E3Z CT101 minimal Ollama worker")
    parser.add_argument("--self-test", action="store_true", help="run repo-only self tests")
    parser.add_argument("--profile-file", default="ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml")
    parser.add_argument("--once", action="store_true", help="run one live job; guarded by EDGE_WORKER_ENABLED=1")
    parser.add_argument("--loop", action="store_true", help="run limited persistent proof loop; guarded by strict proof env")
    parser.add_argument("--job-id", type=int, default=None)
    args = parser.parse_args(argv)

    try:
        if args.self_test:
            return _self_test(args.profile_file)

        config = load_env()
        if args.once:
            return main_once(config, job_id=args.job_id, live=True)
        if args.loop:
            return main_loop(config)

        print("REFUSE_NO_MODE_SELECTED")
        return 2
    except WorkerRefusal as exc:
        print(str(exc))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

