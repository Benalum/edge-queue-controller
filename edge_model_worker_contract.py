"""Stage 16 model worker contract helpers.

This module is intentionally default-off and side-effect free.

It does not call Ollama.
It does not call model endpoints.
It performs no network activity.
It does not write the database.
It does not start workers.
It does not start schedulers.
It is not wired into the live controller in Stage 16-C.

The purpose is to make the future Stage 16-D activation contract explicit,
testable, and easy to inspect before any runtime activation is approved.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass
from typing import Mapping, MutableMapping, Any
import os


STAGE16_ENABLE_ENV = "EDGE_STAGE16_MODEL_WORKER_ENABLED"
STAGE16_CONFIRM_ENV = "EDGE_STAGE16_MODEL_WORKER_CONFIRM"
STAGE16_TEST_MODEL_ENV = "EDGE_STAGE16_TEST_MODEL"
STAGE16_WORKER_ID_ENV = "EDGE_STAGE16_WORKER_ID"

STAGE16_REQUIRED_CONFIRMATION = "APPROVE_STAGE_16_D_ONE_CONTROLLED_QUEUE_MODEL_TEST"

STAGE16_DEFAULT_JOB_TYPE = "companion.chat"
STAGE16_DEFAULT_MODEL = "qwen2.5:0.5b"
STAGE16_DEFAULT_WORKER_ID = "stage16-local-model-worker-1"
STAGE16_DEFAULT_TARGET = "pvew-local-ollama-candidate"
STAGE16_DEFAULT_RESULT_TABLE = "job_results"


def _truthy(value: object) -> bool:
    return str(value or "").strip().lower() in {"1", "true", "yes", "on"}


def _env_value(env: Mapping[str, str] | None, key: str, default: str = "") -> str:
    source = os.environ if env is None else env
    value = source.get(key, default)
    return str(value if value is not None else default).strip()


@dataclass(frozen=True)
class Stage16ModelWorkerContract:
    """Declarative contract for the first future model-worker queue test."""

    enabled: bool
    enable_env: str
    confirmation_env: str
    required_confirmation: str
    selected_target: str
    worker_id: str
    job_type: str
    model_name: str
    result_table: str
    queue_owned_only: bool
    direct_ollama_blocked: bool
    scheduler_broad_activation_allowed: bool
    worker_persistent_enable_allowed: bool
    private_storage_required: bool
    ct204_required: bool


def stage16_model_worker_enabled(env: Mapping[str, str] | None = None) -> bool:
    """Return True only when both the enable flag and confirmation phrase match."""

    enabled = _truthy(_env_value(env, STAGE16_ENABLE_ENV, "0"))
    confirmation = _env_value(env, STAGE16_CONFIRM_ENV, "")
    return enabled and confirmation == STAGE16_REQUIRED_CONFIRMATION


def stage16_contract(env: Mapping[str, str] | None = None) -> dict[str, Any]:
    """Return the default-off model worker contract as plain data."""

    contract = Stage16ModelWorkerContract(
        enabled=stage16_model_worker_enabled(env),
        enable_env=STAGE16_ENABLE_ENV,
        confirmation_env=STAGE16_CONFIRM_ENV,
        required_confirmation=STAGE16_REQUIRED_CONFIRMATION,
        selected_target=STAGE16_DEFAULT_TARGET,
        worker_id=_env_value(env, STAGE16_WORKER_ID_ENV, STAGE16_DEFAULT_WORKER_ID),
        job_type=STAGE16_DEFAULT_JOB_TYPE,
        model_name=_env_value(env, STAGE16_TEST_MODEL_ENV, STAGE16_DEFAULT_MODEL),
        result_table=STAGE16_DEFAULT_RESULT_TABLE,
        queue_owned_only=True,
        direct_ollama_blocked=True,
        scheduler_broad_activation_allowed=False,
        worker_persistent_enable_allowed=False,
        private_storage_required=False,
        ct204_required=False,
    )
    return asdict(contract)


def stage16_validate_candidate_job(job: Mapping[str, Any]) -> dict[str, Any]:
    """Validate whether a job is eligible for the future Stage 16-D test.

    This only validates shape and policy. It does not execute a job.
    """

    job_id = job.get("id") or job.get("job_id")
    job_type = str(job.get("job_type") or "").strip()
    requested_model = str(job.get("requested_model") or "").strip()

    errors: list[str] = []

    if not job_id:
        errors.append("missing_job_id")

    if job_type != STAGE16_DEFAULT_JOB_TYPE:
        errors.append("job_type_not_companion_chat")

    if not requested_model:
        errors.append("missing_requested_model")

    if requested_model == "mock/no-model":
        errors.append("mock_model_not_real_model_test")

    return {
        "ok": not errors,
        "errors": errors,
        "job_id": job_id,
        "job_type": job_type,
        "requested_model": requested_model,
        "queue_owned_only": True,
        "direct_ollama_blocked": True,
    }


def stage16_expected_activation_delta() -> dict[str, int]:
    """Expected DB delta for the later one-job Stage 16-D activation proof."""

    return {
        "jobs": 1,
        "job_results": 1,
        "router_logs": 0,
        "router_resolution_steps": 0,
        "router_feedback": 0,
    }


def stage16_disabled_reason(env: Mapping[str, str] | None = None) -> str:
    """Explain why the Stage 16 model worker path is disabled."""

    if not _truthy(_env_value(env, STAGE16_ENABLE_ENV, "0")):
        return "enable_flag_not_set"
    if _env_value(env, STAGE16_CONFIRM_ENV, "") != STAGE16_REQUIRED_CONFIRMATION:
        return "confirmation_phrase_missing_or_mismatched"
    return ""
