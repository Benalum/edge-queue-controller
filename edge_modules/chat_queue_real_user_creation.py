"""
Real-user queued chat creation helper.

Stage 5F-18.

This helper is intentionally not wired into production routes yet.
It proves that a session-authenticated user can safely create a real-user-shaped
queued chat job using laptop-owned Postgres ownership rules.

Safety:
- disabled unless LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED=1
- also requires LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1
- requires authenticated_user_id from server-side session auth
- refuses client-provided user_id
- verifies chat ownership before reuse
- does not call CT101
- does not call Ollama
- does not persist assistant messages
"""

from __future__ import annotations

import json
import os
import secrets
from dataclasses import dataclass
from typing import Any

from edge_modules.chat_queue_persistence import (
    _jsonb_literal,
    _psql_at,
    _psql_run,
    _sql_literal,
)
from edge_modules.chat_queue_real_user_guard import (
    RealUserQueuedChatGuardError,
    validate_real_user_queued_chat_request,
)


class RealUserQueuedChatCreationError(RuntimeError):
    pass


@dataclass(frozen=True)
class RealUserQueuedChatJob:
    chat_id: str
    user_message_id: str
    job_id: str
    status: str
    payload_json: dict[str, Any]


def real_user_creation_helper_enabled() -> bool:
    return os.environ.get("LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED", "").strip() == "1"


def _require_real_user_creation_enabled() -> None:
    if not real_user_creation_helper_enabled():
        raise RealUserQueuedChatCreationError("real-user queued chat creation helper is disabled")



# STAGE_5G18_DEFAULT_MODEL_ALIAS_RESOLVER_V1
# Treat "default" as a logical model alias, not an Ollama model name.
# The actual default is controlled from one env location.
def resolve_real_user_queued_chat_model_alias(requested_model: str | None) -> str:
    model = str(requested_model or "").strip()

    if model and model.lower() != "default":
        return model

    return (
        os.getenv("AI_PLATFORM_DEFAULT_CHAT_MODEL")
        or os.getenv("EDGE_OLLAMA_DEFAULT_MODEL")
        or os.getenv("LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK")
        or "gemma4:e4b"
    ).strip()


# STAGE_5P11R_MODEL_LANE_CONTRACT_BEGIN
# Contract-only model lane metadata for future lane-aware scheduling.
# This does not change dispatch, worker claiming, Ollama parallelism, or live execution.
def _stage5p11r_int_env(name: str, default: int) -> int:
    try:
        value = int(str(os.getenv(name, "")).strip() or default)
    except Exception:
        value = default
    return max(1, value)


def stage5p11r_model_lane_registry() -> dict[str, dict[str, Any]]:
    return {
        "tiny": {
            "default_model": (os.getenv("AI_PLATFORM_TINY_MODEL") or "qwen3:0.6b").strip(),
            "model_lane": "model-tiny",
            "queue_lane": "model-tiny",
            "max_parallel": _stage5p11r_int_env("AI_PLATFORM_TINY_MODEL_MAX_PARALLEL", 4),
        },
        "small": {
            "default_model": (os.getenv("AI_PLATFORM_SMALL_MODEL") or "qwen3:1.7b").strip(),
            "model_lane": "model-small",
            "queue_lane": "model-small",
            "max_parallel": _stage5p11r_int_env("AI_PLATFORM_SMALL_MODEL_MAX_PARALLEL", 2),
        },
        "medium": {
            "default_model": (os.getenv("AI_PLATFORM_MEDIUM_MODEL") or "gemma3:4b").strip(),
            "model_lane": "model-medium",
            "queue_lane": "model-medium",
            "max_parallel": _stage5p11r_int_env("AI_PLATFORM_MEDIUM_MODEL_MAX_PARALLEL", 1),
        },
        "large": {
            "default_model": (os.getenv("AI_PLATFORM_LARGE_MODEL") or "gemma4:e4b").strip(),
            "model_lane": "model-large",
            "queue_lane": "model-large",
            "max_parallel": _stage5p11r_int_env("AI_PLATFORM_LARGE_MODEL_MAX_PARALLEL", 1),
        },
    }


def stage5p11r_model_tier_for_model(requested_model: str | None, *, mode: str | None = None) -> str:
    model = str(requested_model or "").strip()
    mode_text = str(mode or "").strip().lower()

    for tier, config in stage5p11r_model_lane_registry().items():
        if model and model == str(config.get("default_model") or "").strip():
            return tier

    model_lower = model.lower()

    if "qwen3:0.6b" in model_lower or "0.6b" in model_lower:
        return "tiny"
    if "qwen3:1.7b" in model_lower or "1.7b" in model_lower or "llama3.2:3b" in model_lower:
        return "small"
    if "gemma3:4b" in model_lower or "4b" in model_lower:
        return "medium"
    if mode_text == "companion":
        return "large"

    return "large"


def stage5p11r_build_model_lane_decision(*, requested_model: str | None, mode: str | None) -> dict[str, Any]:
    tier = stage5p11r_model_tier_for_model(requested_model, mode=mode)
    config = stage5p11r_model_lane_registry().get(tier) or stage5p11r_model_lane_registry()["large"]
    mode_text = str(mode or "chat").strip().lower()

    return {
        "version": "stage_5p11r_v1",
        "source": "stage_5p11r_model_lane_contract",
        "intent": "companion_chat" if mode_text == "companion" else "chat_message",
        "confidence": "deterministic",
        "requires_model": True,
        "requested_model": str(requested_model or "").strip(),
        "model_tier": tier,
        "model_lane": str(config["model_lane"]),
        "queue_lane": str(config["queue_lane"]),
        "max_parallel_hint": int(config["max_parallel"]),
        "dispatch_mode": "metadata_only",
        "runtime_behavior_changed": False,
    }
# STAGE_5P11R_MODEL_LANE_CONTRACT_END

def create_real_user_queued_chat_job(
    *,
    authenticated_user_id: str,
    payload: dict[str, Any],
) -> RealUserQueuedChatJob:
    """
    Create a real-user-shaped queued chat job.

    This helper:
    - validates real-user guard rules
    - creates app_chats when chat_id is absent
    - creates user app_messages row
    - creates queued app_jobs row

    This helper does not call CT101 or Ollama.
    This helper does not create assistant messages.
    """
    _require_real_user_creation_enabled()

    try:
        validated = validate_real_user_queued_chat_request(
            authenticated_user_id=authenticated_user_id,
            payload=payload,
        )
    except RealUserQueuedChatGuardError as exc:
        raise RealUserQueuedChatCreationError(str(exc)) from exc

    requested_model = resolve_real_user_queued_chat_model_alias(validated.requested_model)
    routing_decision = stage5p11r_build_model_lane_decision(
        requested_model=requested_model,
        mode=validated.mode,
    )
    chat_id = validated.chat_id or f"s5f18-chat-{secrets.token_hex(8)}"
    user_message_id = f"s5f18-msg-user-{secrets.token_hex(8)}"
    job_id = f"s5f18-job-{secrets.token_hex(8)}"

    if validated.chat_id is None:
        _psql_run(
            f"""
            INSERT INTO app_chats (
              id,
              user_id,
              mode,
              title,
              model,
              created_at,
              updated_at
            )
            VALUES (
              {_sql_literal(chat_id)},
              {_sql_literal(authenticated_user_id)},
              {_sql_literal(validated.mode)},
              {_sql_literal("Stage 5H-2 Queued Companion" if validated.mode == "companion" else "Stage 5F-18 Queued Chat")},
              {_sql_literal(requested_model)},
              now(),
              now()
            );
            """
        )

    payload_json = {
        "chat_id": chat_id,
        "user_message_id": user_message_id,
        "prompt": validated.message,
        "messages": [{"role": "user", "content": validated.message}],
        "mode": validated.mode,
        "route_source": "stage_5h2_real_user_mode_aware_creation_helper",
        "synthetic": False,
        "requested_model": requested_model,
        "routing_contract_version": routing_decision["version"],
        "routing_decision": routing_decision,
        "model_tier": routing_decision["model_tier"],
        "model_lane": routing_decision["model_lane"],
        "queue_lane": routing_decision["queue_lane"],
        "model_max_parallel_hint": routing_decision["max_parallel_hint"],
    }

    _psql_run(
        f"""
        BEGIN;

        INSERT INTO app_messages (
          id,
          chat_id,
          role,
          content,
          risk_level,
          source_job_id,
          created_at
        )
        VALUES (
          {_sql_literal(user_message_id)},
          {_sql_literal(chat_id)},
          'user',
          {_sql_literal(validated.message)},
          0,
          NULL,
          now()
        );

        INSERT INTO app_jobs (
          id,
          user_id,
          job_type,
          status,
          requested_model,
          assigned_worker_id,
          payload_json,
          result_json,
          error_text,
          created_at,
          updated_at,
          started_at,
          finished_at
        )
        VALUES (
          {_sql_literal(job_id)},
          {_sql_literal(authenticated_user_id)},
          'ollama_chat',
          'queued',
          {_sql_literal(requested_model)},
          NULL,
          {_jsonb_literal(payload_json)},
          NULL,
          NULL,
          now(),
          now(),
          NULL,
          NULL
        );

        COMMIT;
        """
    )

    raw = _psql_at(
        f"""
        SELECT row_to_json(j)::text
        FROM (
          SELECT
            id AS job_id,
            status,
            payload_json
          FROM app_jobs
          WHERE id = {_sql_literal(job_id)}
            AND user_id = {_sql_literal(authenticated_user_id)}
        ) j;
        """
    )

    if not raw:
        raise RealUserQueuedChatCreationError("created real-user queued job could not be read back")

    parsed = json.loads(raw)

    return RealUserQueuedChatJob(
        chat_id=chat_id,
        user_message_id=user_message_id,
        job_id=parsed["job_id"],
        status=parsed["status"],
        payload_json=parsed["payload_json"],
    )
