"""Universal Intent Router deterministic dry-run helpers.

This module contains the disabled-router helper logic used by Stage 6F+.

It does not dispatch.
It does not call models.
It does not mutate application state.
"""

import os


def _stage6f_router_enabled():
    return str(os.getenv("EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED", "0")).lower() in {"1", "true", "yes", "on"}


def _stage6f_router_response(body):
    if not isinstance(body, dict):
        body = {}

    input_obj = body.get("input") if isinstance(body.get("input"), dict) else {}
    context_obj = body.get("context") if isinstance(body.get("context"), dict) else {}

    text = str(input_obj.get("text") or "").strip()
    lowered = text.lower()
    source = str(input_obj.get("source") or "").lower()
    surface = str(input_obj.get("surface") or "").lower()
    active_page = str(context_obj.get("active_page") or "").lower()

    study_context = source == "study" or surface.startswith("study") or active_page == "study"
    companion_context = source in {"companion", "chat"} or active_page in {"companion", "chat"}

    language_detected = "es" if lowered in {"siguiente", "próximo", "proximo", "saltar", "omitir", "pista", "ayuda"} else "en"

    intent_name = "unknown.unsupported"
    confidence = 0.0
    handler = None
    route = None
    tier = "fast_intent"
    reason = "No supported dry-run intent matched."

    if study_context and lowered in {"next", "n", "continue", "move on", "go on", "next card", "siguiente", "próximo", "proximo"}:
        intent_name = "study.next"
        confidence = 0.98
        handler = "study.session.command"
        route = "/api/study/session/command"
        reason = "Short study navigation command."
    elif study_context and lowered in {"skip", "pass", "i don't know", "i dont know", "idk", "don't know", "dont know", "not sure", "saltar", "omitir"}:
        intent_name = "study.skip"
        confidence = 0.96
        handler = "study.session.command"
        route = "/api/study/session/command"
        reason = "Short study skip command."
    elif study_context and lowered in {"hint", "help", "show hint", "give me a hint", "pista", "ayuda"}:
        intent_name = "study.hint"
        confidence = 0.94
        handler = "study.session.command"
        route = "/api/study/session/command"
        reason = "Short study hint command."
    elif study_context and text:
        intent_name = "study.answer"
        confidence = 0.70
        handler = "study.session.command"
        route = "/api/study/session/command"
        reason = "Study text input."
    elif companion_context and text:
        intent_name = "companion.chat"
        confidence = 0.75
        handler = "companion.chat"
        route = "/api/companion/chat"
        tier = "medium_conversation"
        reason = "Companion/chat text input."
    elif text:
        intent_name = "unknown.general_chat"
        confidence = 0.35
        handler = "companion.chat"
        route = "/api/companion/chat"
        tier = "medium_conversation"
        reason = "General text input without strong page context."

    return {
        "ok": True,
        "dry_run": True,
        "dispatch_performed": False,
        "language": {
            "detected": language_detected,
            "profile_default": "en",
            "response_language": language_detected,
            "confidence": 0.80 if text else 0.0,
        },
        "intent": {
            "name": intent_name,
            "confidence": confidence,
            "slots": {},
            "reason": reason,
        },
        "target": {
            "route_class": "router_candidate" if route else "none",
            "handler": handler,
            "existing_route": route,
            "method": "POST" if route else None,
        },
        "model_routing": {
            "tier": tier,
            "model": "none",
            "model_call_required": False,
        },
        "safety": {
            "safety_class": "user_content_write" if route else "read_only",
            "requires_confirmation": False,
            "allowed_in_dry_run": True,
            "allowed_to_dispatch": False,
        },
        "actions": [
            {
                "type": "would_dispatch" if route else "would_not_dispatch",
                "handler": handler,
                "route": route,
                "dispatch_blocked_reason": "dry_run_endpoint_never_dispatches",
            }
        ],
        "errors": [],
    }
