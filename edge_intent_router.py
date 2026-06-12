"""Universal Intent Router deterministic dry-run helpers.

This module contains the disabled-router helper logic used by Stage 6F+.

It does not dispatch.
It does not call models.
It does not mutate application state.
"""

import os


def _stage6f_confidence_band(confidence):
    if confidence >= 0.90:
        return "high"
    if confidence >= 0.70:
        return "medium"
    if confidence > 0:
        return "low"
    return "none"


def _stage6f_confirmation_policy(intent_name, route, confidence):
    confidence_band = _stage6f_confidence_band(confidence)

    write_like_prefixes = (
        "calendar.write",
        "profile.preference_update",
        "admin.",
    )

    would_require_confirmation = intent_name.startswith(write_like_prefixes)

    return {
        "requires_confirmation": False,
        "would_require_confirmation_if_dispatch_enabled": would_require_confirmation,
        "confirmation_status": "not_required_for_dry_run",
        "confidence_band": confidence_band,
        "eligible_for_dispatch": False,
        "dispatch_disabled_reason": "dry_run_endpoint_never_dispatches",
        "route": route,
    }



def _stage6f_source_surface_policy(source, surface, active_page):
    restricted_tokens = {
        "admin",
        "auth",
        "internal",
        "power",
        "security",
        "system",
        "worker",
        "queue",
        "password",
        "billing",
        "account-bootstrap",
    }

    values = {
        "source": str(source or "").strip().lower(),
        "surface": str(surface or "").strip().lower(),
        "active_page": str(active_page or "").strip().lower(),
    }

    restricted_match = None

    for field, value in values.items():
        if not value:
            continue

        parts = {
            value,
            value.split("_", 1)[0],
            value.split("-", 1)[0],
            value.split("/", 1)[0],
        }

        if value in restricted_tokens:
            restricted_match = {"field": field, "value": value}
            break

        if parts & restricted_tokens:
            restricted_match = {"field": field, "value": value}
            break

        for token in restricted_tokens:
            if value.startswith(token + "_") or value.startswith(token + "-") or value.startswith(token + "/"):
                restricted_match = {"field": field, "value": value}
                break

        if restricted_match:
            break

    allowed = restricted_match is None

    return {
        "allowed": allowed,
        "policy": "stage6m_user_surface_allowlist",
        "reason": "allowed_user_facing_surface" if allowed else "blocked_restricted_surface",
        "source": values["source"],
        "surface": values["surface"],
        "active_page": values["active_page"],
        "restricted_match": restricted_match,
        "blocked_surface_groups": sorted(restricted_tokens),
    }

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

    source_surface_policy = _stage6f_source_surface_policy(source, surface, active_page)

    study_context = source_surface_policy["allowed"] and (source == "study" or surface.startswith("study") or active_page == "study")
    companion_context = source_surface_policy["allowed"] and (source in {"companion", "chat"} or active_page in {"companion", "chat"})

    language_detected = "es" if lowered in {"siguiente", "próximo", "proximo", "saltar", "omitir", "pista", "ayuda"} else "en"

    intent_name = "unknown.unsupported"
    confidence = 0.0
    handler = None
    route = None
    tier = "fast_intent"
    reason = "No supported dry-run intent matched."
    rule_id = "unknown.unsupported.empty_or_no_match"

    decision_trace = [
        {
            "step": "normalize_input",
            "text_present": bool(text),
            "normalized_text": lowered,
            "source": source,
            "surface": surface,
            "active_page": active_page,
            "study_context": study_context,
            "companion_context": companion_context,
            "source_surface_policy": source_surface_policy,
        }
    ]

    if not source_surface_policy["allowed"]:
        intent_name = "unknown.unsupported"
        confidence = 0.0
        handler = None
        route = None
        tier = "fast_intent"
        reason = "Input source, surface, or active page is blocked by router source/surface policy."
        rule_id = "policy.source_surface.blocked"
    elif study_context and lowered in {"next", "n", "continue", "move on", "go on", "next card", "siguiente", "próximo", "proximo"}:
        intent_name = "study.next"
        confidence = 0.98
        handler = "study.session.command"
        route = "/api/study/session/command"
        reason = "Short study navigation command."
        rule_id = "study.next.alias"
    elif study_context and lowered in {"skip", "pass", "i don't know", "i dont know", "idk", "don't know", "dont know", "not sure", "saltar", "omitir"}:
        intent_name = "study.skip"
        confidence = 0.96
        handler = "study.session.command"
        route = "/api/study/session/command"
        reason = "Short study skip command."
        rule_id = "study.skip.alias"
    elif study_context and lowered in {"hint", "help", "show hint", "give me a hint", "pista", "ayuda"}:
        intent_name = "study.hint"
        confidence = 0.94
        handler = "study.session.command"
        route = "/api/study/session/command"
        reason = "Short study hint command."
        rule_id = "study.hint.alias"
    elif study_context and text:
        intent_name = "study.answer"
        confidence = 0.70
        handler = "study.session.command"
        route = "/api/study/session/command"
        reason = "Study text input."
        rule_id = "study.answer.text"
    elif companion_context and text:
        intent_name = "companion.chat"
        confidence = 0.75
        handler = "companion.chat"
        route = "/api/companion/chat"
        tier = "medium_conversation"
        reason = "Companion/chat text input."
        rule_id = "companion.chat.text"
    elif text:
        intent_name = "unknown.general_chat"
        confidence = 0.35
        handler = "companion.chat"
        route = "/api/companion/chat"
        tier = "medium_conversation"
        reason = "General text input without strong page context."
        rule_id = "unknown.general_chat.text"

    confidence_band = _stage6f_confidence_band(confidence)
    confirmation_policy = _stage6f_confirmation_policy(intent_name, route, confidence)

    decision_trace.append(
        {
            "step": "rule_result",
            "rule_id": rule_id,
            "intent": intent_name,
            "confidence": confidence,
            "confidence_band": confidence_band,
            "handler": handler,
            "route": route,
            "model_tier": tier,
            "dispatch_blocked_reason": "dry_run_endpoint_never_dispatches",
        }
    )

    return {
        "ok": True,
        "dry_run": True,
        "dispatch_performed": False,
        "source_surface_policy": source_surface_policy,
        "decision_trace": decision_trace,
        "language": {
            "detected": language_detected,
            "profile_default": "en",
            "response_language": language_detected,
            "confidence": 0.80 if text else 0.0,
        },
        "intent": {
            "name": intent_name,
            "confidence": confidence,
            "confidence_band": confidence_band,
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
        "confirmation_policy": confirmation_policy,
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


def _stage6q_extract_study_text(payload):
    if not isinstance(payload, dict):
        return ""

    input_obj = payload.get("input") if isinstance(payload.get("input"), dict) else {}

    for value in [
        input_obj.get("text"),
        payload.get("text"),
        payload.get("command"),
        payload.get("action"),
        payload.get("answer"),
        payload.get("message"),
        payload.get("input_text"),
    ]:
        text = str(value or "").strip()
        if text:
            return text

    return ""


def _stage6q_study_adapter_shadow(payload):
    """Return a dry-run-only Study adapter shadow result.

    This helper does not dispatch.
    This helper does not call models.
    This helper does not mutate Study state.
    This helper is not wired into any Study route.
    """

    if not isinstance(payload, dict):
        payload = {}

    text = _stage6q_extract_study_text(payload)

    router_body = {
        "input": {
            "text": text,
            "source": "study",
            "surface": "study_session",
            "locale_hint": payload.get("locale_hint") or "en-US",
        },
        "context": {
            "active_page": "study",
            "profile_language": payload.get("profile_language") or "en",
            "role": payload.get("role") or "user",
        },
        "page_context": {
            "shadow_adapter": "stage6q_study",
            "mode": payload.get("mode") or "review",
        },
        "router_options": {
            "dry_run": True,
            "allow_dispatch": False,
            "allow_model_call": False,
            "max_model_tier": "fast_intent",
        },
    }

    router_result = _stage6f_router_response(router_body)

    return {
        "ok": True,
        "stage": "6Q",
        "adapter": "study_shadow_dry_run",
        "behavior_changed": False,
        "dispatch_performed": False,
        "model_call_required": router_result["model_routing"]["model_call_required"],
        "allowed_to_dispatch": False,
        "source_payload_keys": sorted(str(k) for k in payload.keys()),
        "normalized_router_input": router_body,
        "router_result": router_result,
        "shadow_summary": {
            "text_present": bool(text),
            "intent": router_result["intent"]["name"],
            "confidence_band": router_result["intent"]["confidence_band"],
            "existing_route": router_result["target"]["existing_route"],
            "rule_id": router_result["decision_trace"][-1]["rule_id"],
            "source_surface_allowed": router_result["source_surface_policy"]["allowed"],
        },
        "errors": [],
    }


def _stage6v_extract_companion_text(payload):
    if not isinstance(payload, dict):
        return ""

    input_obj = payload.get("input") if isinstance(payload.get("input"), dict) else {}

    for value in [
        input_obj.get("text"),
        payload.get("text"),
        payload.get("message"),
        payload.get("prompt"),
        payload.get("content"),
        payload.get("input_text"),
    ]:
        text = str(value or "").strip()
        if text:
            return text

    return ""


def _stage6v_companion_adapter_shadow(payload):
    """Return a dry-run-only Companion adapter shadow result.

    This helper does not dispatch.
    This helper does not call models.
    This helper does not mutate Companion, Calendar, Profile, or Study state.
    This helper is not wired into any Companion or Chat route.
    """

    if not isinstance(payload, dict):
        payload = {}

    input_obj = payload.get("input") if isinstance(payload.get("input"), dict) else {}
    context_obj = payload.get("context") if isinstance(payload.get("context"), dict) else {}

    text = _stage6v_extract_companion_text(payload)

    source = str(input_obj.get("source") or payload.get("source") or "companion").strip() or "companion"
    surface = str(input_obj.get("surface") or payload.get("surface") or "companion_chat").strip() or "companion_chat"
    active_page = str(context_obj.get("active_page") or payload.get("active_page") or "companion").strip() or "companion"

    router_body = {
        "input": {
            "text": text,
            "source": source,
            "surface": surface,
            "locale_hint": payload.get("locale_hint") or "en-US",
        },
        "context": {
            "active_page": active_page,
            "profile_language": payload.get("profile_language") or "en",
            "role": payload.get("role") or "user",
        },
        "page_context": {
            "shadow_adapter": "stage6v_companion",
            "mode": payload.get("mode") or "conversation",
        },
        "router_options": {
            "dry_run": True,
            "allow_dispatch": False,
            "allow_model_call": False,
            "max_model_tier": payload.get("max_model_tier") or "medium",
        },
    }

    router_result = _stage6f_router_response(router_body)

    return {
        "ok": True,
        "stage": "6V",
        "adapter": "companion_shadow_dry_run",
        "behavior_changed": False,
        "dispatch_performed": False,
        "model_call_required": router_result["model_routing"]["model_call_required"],
        "allowed_to_dispatch": False,
        "source_payload_keys": sorted(str(k) for k in payload.keys()),
        "normalized_router_input": router_body,
        "router_result": router_result,
        "shadow_summary": {
            "text_present": bool(text),
            "intent": router_result["intent"]["name"],
            "confidence_band": router_result["intent"]["confidence_band"],
            "existing_route": router_result["target"]["existing_route"],
            "rule_id": router_result["decision_trace"][-1]["rule_id"],
            "model_tier": router_result["model_routing"]["tier"],
            "source_surface_allowed": router_result["source_surface_policy"]["allowed"],
        },
        "errors": [],
    }

