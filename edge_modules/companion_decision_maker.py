#!/usr/bin/env python3
"""Stage 16 FC-O45-F/G Companion Decision Maker contract.

Pure, deterministic helper. Safe to import and self-test.
No DB writes, no queue writes, no model calls, no network calls.
"""

from __future__ import annotations

import json
import re
from dataclasses import asdict, dataclass
from typing import Any, Dict, List, Optional


@dataclass(frozen=True)
class CompanionDecision:
    ok: bool
    decision_version: int
    surface: str
    action: str
    decision_type: str
    job_type: str
    lane: str
    requested_model_policy: str
    model_call_allowed: bool
    queue_allowed: bool
    study_context_allowed: bool
    study_mutation_allowed: bool
    tool_permissions: List[str]
    reason_code: str
    confidence: float
    user_id: Optional[int]
    safety_flags: List[str]
    normalized_input: str

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


def _norm(value: str) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip().lower())


def _clip(value: str, limit: int = 500) -> str:
    clean = str(value or "").strip()
    return clean if len(clean) <= limit else clean[: limit - 3].rstrip() + "..."


def decide_companion_action(
    *,
    user_id: int | None,
    message: str,
    study_context: Dict[str, Any] | None = None,
    allow_queue: bool = False,
    allow_model: bool = False,
) -> CompanionDecision:
    """Classify a Companion message into a safe backend action.

    The booleans intentionally default to False. Runtime wiring must explicitly
    opt in to queue/model use after read-only and mock proofs pass.
    """

    text = _norm(message)
    study_context = study_context if isinstance(study_context, dict) else {}
    has_study_context = bool(study_context)

    decision_type = "companion_chat"
    action = "answer"
    job_type = "companion.chat"
    lane = "companion"
    model_policy = "backend-deterministic/no-model-first"
    tool_permissions: List[str] = ["companion.last_message"]
    reason_code = "general_companion_message"
    confidence = 0.65
    study_context_allowed = False
    study_mutation_allowed = False

    if not text:
        decision_type = "refusal_or_safe_reply"
        action = "empty_message_help"
        job_type = "none"
        lane = "none"
        reason_code = "empty_message"
        confidence = 1.0
        tool_permissions = []
    elif any(word in text for word in ("flashcard", "flash card", "quiz me", "practice question")):
        decision_type = "study_flashcard_help"
        action = "study_flashcard_candidates"
        job_type = "companion.chat"
        lane = "study_companion"
        reason_code = "study_flashcard_request"
        confidence = 0.86
        study_context_allowed = True
        tool_permissions = ["study.read_context", "study.make_flashcard_candidates_no_save"]
    elif any(word in text for word in ("study", "explain", "hint", "read answer", "show answer", "correct", "wrong", "skip")):
        decision_type = "study_explain"
        action = "study_coach_or_command"
        job_type = "companion.chat"
        lane = "study_companion"
        reason_code = "study_help_or_review_request"
        confidence = 0.82
        study_context_allowed = True
        tool_permissions = ["study.read_context", "study.session_command_if_explicit"]
    elif any(word in text for word in ("password", "secret", "token", "api key", "private key")):
        decision_type = "refusal_or_safe_reply"
        action = "safety_boundary_reply"
        job_type = "companion.chat"
        lane = "companion"
        reason_code = "secret_or_sensitive_system_request"
        confidence = 0.9
        tool_permissions = ["companion.safe_reply"]

    if has_study_context and decision_type.startswith("study_"):
        reason_code += "_with_context"

    safety_flags = [
        "auth_required_by_caller",
        "browser_cannot_select_model",
        "no_direct_browser_to_ollama",
        "study_mutation_default_false",
    ]
    if not allow_queue:
        safety_flags.append("queue_disabled_for_preview")
    if not allow_model:
        safety_flags.append("model_disabled_for_preview")

    return CompanionDecision(
        ok=True,
        decision_version=1,
        surface="companion_study",
        action=action,
        decision_type=decision_type,
        job_type=job_type,
        lane=lane,
        requested_model_policy=model_policy,
        model_call_allowed=bool(allow_model and allow_queue and job_type != "none"),
        queue_allowed=bool(allow_queue and job_type != "none"),
        study_context_allowed=study_context_allowed,
        study_mutation_allowed=study_mutation_allowed,
        tool_permissions=tool_permissions,
        reason_code=reason_code,
        confidence=confidence,
        user_id=int(user_id) if user_id is not None else None,
        safety_flags=safety_flags,
        normalized_input=_clip(text),
    )


def self_test() -> None:
    empty = decide_companion_action(user_id=1, message="")
    assert empty.decision_type == "refusal_or_safe_reply"
    assert empty.queue_allowed is False
    assert empty.model_call_allowed is False

    general = decide_companion_action(user_id=1, message="hello companion")
    assert general.decision_type == "companion_chat"
    assert general.job_type == "companion.chat"

    study = decide_companion_action(user_id=1, message="explain this study card", study_context={"deck_id": 7})
    assert study.decision_type == "study_explain"
    assert study.study_context_allowed is True
    assert study.study_mutation_allowed is False

    flash = decide_companion_action(user_id=1, message="make flashcards from this note")
    assert flash.decision_type == "study_flashcard_help"
    assert "study.make_flashcard_candidates_no_save" in flash.tool_permissions

    live = decide_companion_action(user_id=1, message="hello", allow_queue=True, allow_model=True)
    assert live.queue_allowed is True
    assert live.model_call_allowed is True
    assert "browser_cannot_select_model" in live.safety_flags


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser(description="Preview the Companion Decision Maker contract.")
    parser.add_argument("message", nargs="*", help="Message to classify")
    parser.add_argument("--user-id", type=int, default=0)
    parser.add_argument("--allow-queue", action="store_true")
    parser.add_argument("--allow-model", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        print("companion_decision_maker_self_test=PASS")
        return 0

    decision = decide_companion_action(
        user_id=args.user_id or None,
        message=" ".join(args.message),
        allow_queue=args.allow_queue,
        allow_model=args.allow_model,
    )
    print(json.dumps(decision.to_dict(), ensure_ascii=False, sort_keys=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
