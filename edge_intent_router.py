"""Universal Intent Router deterministic dry-run helpers.

This module contains the disabled-router helper logic used by Stage 6F+.

It does not dispatch.
It does not call models.
It does not mutate application state.
"""

import os
import sqlite3
from pathlib import Path

from edge_router_lookup import lookup_router_exact_phrase, normalize_router_phrase


def _stage6af_router_db_path():
    """Return the SQLite DB path used for read-only router phrase lookup."""

    return Path(os.getenv("EDGE_ROUTER_SQLITE_DB_PATH", "edge_queue.sqlite3"))


def _stage6af_lookup_context_domain(study_context, companion_context):
    """Choose a safe context domain for read-only phrase lookup."""

    if study_context:
        return "study"
    if companion_context:
        return "companion"
    return "global"


def _stage6af_sqlite_phrase_lookup(text, language_code, context_domain):
    """Stage 6AF: read-only SQLite phrase lookup for dry-run observability.

    This helper never dispatches.
    This helper never calls a model.
    This helper returns lookup metadata only.
    """

    safe_result = {
        "ok": False,
        "matched": False,
        "source": "global_phrase_bank",
        "input_text": text,
        "language_code": language_code,
        "context_domain": context_domain,
        "intent_key": None,
        "intent": None,
        "route": None,
        "dispatch_performed": False,
        "model_call_required": False,
    }

    if not str(text or "").strip():
        safe_result["error_code"] = "empty_input"
        return safe_result

    db_path = _stage6af_router_db_path()
    safe_result["db_path"] = str(db_path)

    if not db_path.exists():
        safe_result["error_code"] = "router_db_not_found"
        return safe_result

    try:
        conn = sqlite3.connect(db_path)
        try:
            result = lookup_router_exact_phrase(
                conn,
                text,
                language_code=language_code,
                context_domain=context_domain,
            )
            result["db_path"] = str(db_path)
            result["dispatch_performed"] = False
            result["model_call_required"] = False
            return result
        finally:
            conn.close()
    except Exception as exc:  # pragma: no cover - defensive runtime guard
        safe_result["error_code"] = "router_db_lookup_failed"
        safe_result["error"] = repr(exc)
        return safe_result



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
    normalized_phrase = normalize_router_phrase(text)
    source = str(input_obj.get("source") or "").lower()
    surface = str(input_obj.get("surface") or "").lower()
    active_page = str(context_obj.get("active_page") or "").lower()

    source_surface_policy = _stage6f_source_surface_policy(source, surface, active_page)

    study_context = source_surface_policy["allowed"] and (source == "study" or surface.startswith("study") or active_page == "study")
    companion_context = source_surface_policy["allowed"] and (source in {"companion", "chat"} or active_page in {"companion", "chat"})

    language_detected = "es" if normalized_phrase in {"siguiente", "proximo", "saltar", "omitir", "pista", "ayuda", "mostrar respuesta", "respuesta", "correcto", "incorrecto"} else "en"

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
            "normalized_phrase": normalized_phrase,
            "source": source,
            "surface": surface,
            "active_page": active_page,
            "study_context": study_context,
            "companion_context": companion_context,
            "source_surface_policy": source_surface_policy,
        }
    ]

    lookup_context_domain = _stage6af_lookup_context_domain(study_context, companion_context)

    if source_surface_policy["allowed"]:
        sqlite_phrase_lookup = _stage6af_sqlite_phrase_lookup(
            text,
            language_detected,
            lookup_context_domain,
        )
    else:
        sqlite_phrase_lookup = {
            "ok": False,
            "matched": False,
            "source": "global_phrase_bank",
            "input_text": text,
            "normalized_phrase": normalized_phrase,
            "language_code": language_detected,
            "context_domain": lookup_context_domain,
            "intent_key": None,
            "intent": None,
            "route": None,
            "error_code": "source_surface_policy_blocked",
            "dispatch_performed": False,
            "model_call_required": False,
        }

    decision_trace.append(
        {
            "step": "sqlite_phrase_lookup",
            "lookup_enabled": True,
            "lookup_source": sqlite_phrase_lookup.get("source"),
            "matched": bool(sqlite_phrase_lookup.get("matched")),
            "intent_key": sqlite_phrase_lookup.get("intent_key"),
            "context_domain": sqlite_phrase_lookup.get("context_domain"),
            "language_code": sqlite_phrase_lookup.get("language_code"),
            "error_code": sqlite_phrase_lookup.get("error_code"),
            "dispatch_blocked_reason": "dry_run_endpoint_never_dispatches",
        }
    )

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

    result = {
        "ok": True,
        "dry_run": True,
        "dispatch_performed": False,
        "source_surface_policy": source_surface_policy,
        "decision_trace": decision_trace,
        "router_lookup": {
            "stage": "6AF",
            "sqlite_phrase_lookup": sqlite_phrase_lookup,
            "dispatch_performed": False,
            "model_call_required": False,
        },
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

    # STAGE_8F_ROUTER_RESPONSE_DECISION_CONTRACT_V1
    # Add a contract-shaped decision object while preserving the legacy response.
    # This does not dispatch, does not call models, and remains gated by the disabled live endpoint.
    decision_contract = _stage8d_router_decision_contract(result)
    # The standalone adapter may include the original router_result for unit/debug use.
    # When nested into the HTTP response, remove it to avoid a circular JSON object:
    # result -> decision_contract -> router_result -> result.
    decision_contract.pop("router_result", None)
    result["decision_contract"] = decision_contract
    return result


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



# STAGE_8D_DECISION_CONTRACT_ADAPTER_V1
def _stage8d_selected_path_from_intent(
    *,
    intent_key=None,
    legacy_intent_name=None,
    route_type=None,
    target_service=None,
    source_surface_allowed=True,
):
    """Map current router result fields into the Stage 8B selected_path contract.

    This helper is source-only and does not dispatch.
    """
    if source_surface_allowed is False:
        return "unsupported"

    canonical = str(intent_key or "").strip()
    legacy = str(legacy_intent_name or "").strip()
    route = str(route_type or "").strip()
    service = str(target_service or "").strip()

    if canonical.startswith("study.") or legacy.startswith("study."):
        return "study_command"

    if canonical.startswith("companion.") or legacy == "companion.chat" or service == "companion":
        return "companion_chat"

    if canonical.startswith("chat.") or legacy == "unknown.general_chat" or service == "chat":
        return "general_chat"

    if canonical.startswith("calendar.") or service == "calendar":
        return "calendar_command"

    if route == "navigation":
        return "navigation"

    if service in {"profile", "settings"}:
        return "profile_or_settings"

    if legacy == "unknown.unsupported" or canonical == "unknown.unsupported":
        return "unsupported"

    if route == "none":
        return "unsupported"

    return "unsupported"


def _stage8d_bool_from_nested(data, path, default=False):
    """Read a nested boolean safely from a dict."""
    current = data
    for key in path:
        if not isinstance(current, dict) or key not in current:
            return default
        current = current[key]
    if isinstance(current, bool):
        return current
    return default


def _stage8d_router_decision_contract(router_result):
    """Normalize the existing router result into the Stage 8B decision-maker contract.

    Stage 8D is an adapter only:
    - does not enable live routing
    - does not dispatch
    - does not call models
    - preserves the existing router result for compatibility
    """
    if not isinstance(router_result, dict):
        router_result = {}

    intent = router_result.get("intent") if isinstance(router_result.get("intent"), dict) else {}
    target = router_result.get("target") if isinstance(router_result.get("target"), dict) else {}
    model_routing = router_result.get("model_routing") if isinstance(router_result.get("model_routing"), dict) else {}
    safety = router_result.get("safety") if isinstance(router_result.get("safety"), dict) else {}
    confirmation_policy = router_result.get("confirmation_policy") if isinstance(router_result.get("confirmation_policy"), dict) else {}
    source_policy = router_result.get("source_surface_policy") if isinstance(router_result.get("source_surface_policy"), dict) else {}
    router_lookup = router_result.get("router_lookup") if isinstance(router_result.get("router_lookup"), dict) else {}
    sqlite_lookup = router_lookup.get("sqlite_phrase_lookup") if isinstance(router_lookup.get("sqlite_phrase_lookup"), dict) else {}

    legacy_intent_name = intent.get("name") or router_result.get("legacy_intent_name") or "unknown.unsupported"
    intent_key = sqlite_lookup.get("intent_key") or router_result.get("intent_key") or None

    route = sqlite_lookup.get("route") if isinstance(sqlite_lookup.get("route"), dict) else {}
    phrase = sqlite_lookup.get("phrase") if isinstance(sqlite_lookup.get("phrase"), dict) else {}

    route_type = (
        route.get("route_type")
        or target.get("route_type")
        or target.get("route_class")
        or None
    )
    target_service = (
        route.get("target_service")
        or target.get("target_service")
        or target.get("service")
        or None
    )
    target_handler = (
        route.get("target_handler")
        or target.get("target_handler")
        or target.get("handler")
        or None
    )

    source_surface_allowed = source_policy.get("allowed", True)

    selected_path = _stage8d_selected_path_from_intent(
        intent_key=intent_key,
        legacy_intent_name=legacy_intent_name,
        route_type=route_type,
        target_service=target_service,
        source_surface_allowed=source_surface_allowed,
    )

    model_call_required = bool(model_routing.get("model_call_required", False))
    allowed_to_dispatch = bool(safety.get("allowed_to_dispatch", False))
    eligible_for_dispatch = bool(confirmation_policy.get("eligible_for_dispatch", False))
    dispatch_performed = bool(router_result.get("dispatch_performed", False))
    dry_run = bool(router_result.get("dry_run", True))

    needs_confirmation = bool(
        confirmation_policy.get("would_require_confirmation_if_dispatch_enabled", False)
        or confirmation_policy.get("confirmation_required", False)
        or route.get("confirmation_required", False)
    )

    confidence = intent.get("confidence", router_result.get("confidence", 0.0))
    try:
        confidence = float(confidence)
    except Exception:
        confidence = 0.0

    language = router_result.get("language") if isinstance(router_result.get("language"), dict) else {}

    context_domain = (
        sqlite_lookup.get("context_domain")
        or phrase.get("context_domain")
        or router_result.get("context_domain")
        or None
    )

    language_code = (
        sqlite_lookup.get("language_code")
        or phrase.get("language_code")
        or language.get("detected")
        or router_result.get("language_code")
        or "en"
    )

    candidate_routes = []
    if route:
        candidate_routes.append(
            {
                "source": "sqlite_phrase_lookup",
                "intent_key": intent_key,
                "route_type": route.get("route_type"),
                "target_service": route.get("target_service"),
                "target_handler": route.get("target_handler"),
                "min_confidence": route.get("min_confidence"),
                "confirmation_required": bool(route.get("confirmation_required", False)),
                "enabled": bool(route.get("enabled", True)),
            }
        )
    elif target.get("existing_route") or target_service or target_handler:
        candidate_routes.append(
            {
                "source": "legacy_target",
                "intent_key": intent_key,
                "route_type": route_type,
                "target_service": target_service,
                "target_handler": target_handler,
                "existing_route": target.get("existing_route"),
                "enabled": True,
            }
        )

    if not candidate_routes:
        candidate_routes.append(
            {
                "source": "none",
                "intent_key": intent_key,
                "route_type": "none",
                "target_service": None,
                "target_handler": None,
                "enabled": False,
            }
        )

    dispatch_plan = {
        "type": "dry_run_plan",
        "selected_path": selected_path,
        "would_dispatch": bool(
            not dry_run
            and allowed_to_dispatch
            and eligible_for_dispatch
            and not needs_confirmation
            and selected_path not in {"unsupported", "needs_confirmation", "no_action"}
        ),
        "dispatch_performed": dispatch_performed,
        "allowed_to_dispatch": allowed_to_dispatch,
        "eligible_for_dispatch": eligible_for_dispatch,
        "model_call_required": model_call_required,
        "target_service": target_service,
        "target_handler": target_handler,
        "existing_route": target.get("existing_route"),
        "blocked_reason": "dry_run_endpoint_never_dispatches" if dry_run else safety.get("dispatch_blocked_reason"),
    }

    if needs_confirmation and selected_path not in {"unsupported", "no_action"}:
        contract_selected_path = "needs_confirmation" if allowed_to_dispatch else selected_path
    else:
        contract_selected_path = selected_path

    return {
        "ok": bool(router_result.get("ok", True)),
        "dry_run": dry_run,
        "dispatch_performed": dispatch_performed,
        "model_call_required": model_call_required,
        "selected_path": contract_selected_path,
        "intent_key": intent_key,
        "legacy_intent_name": legacy_intent_name,
        "confidence": confidence,
        "needs_confirmation": needs_confirmation,
        "reason": router_result.get("reason") or intent.get("reason") or "",
        "surface": router_result.get("surface") or source_policy.get("surface") or None,
        "context_domain": context_domain,
        "language_code": language_code,
        "decision_trace": router_result.get("decision_trace", []),
        "candidate_routes": candidate_routes,
        "dispatch_plan": dispatch_plan,
        "allowed_to_dispatch": allowed_to_dispatch,
        "eligible_for_dispatch": eligible_for_dispatch,
        "source_surface_allowed": source_surface_allowed,
        "router_result": router_result,
    }
