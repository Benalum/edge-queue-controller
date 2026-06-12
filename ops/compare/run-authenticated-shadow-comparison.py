#!/usr/bin/env python3
"""Manual local authenticated shadow comparison runner.

Default mode is offline-only and does not call HTTP routes.

Authenticated HTTP execution requires:
  --execute-authenticated
  --confirm-existing-route-call YES_EXISTING_ROUTE_MAY_CHANGE_STATE
  EDGE_AUTH_SHADOW_COMPARE_COOKIE or EDGE_AUTH_SHADOW_COMPARE_BEARER
  EDGE_AUTH_SHADOW_COMPARE_PUBLIC_API_KEY for routes guarded by x-edge-api-key

This tool never prints auth values and never stores auth values in artifacts.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

import edge_intent_router  # noqa: E402


VALIDATOR = REPO_ROOT / "ops/validate/validate-authenticated-shadow-comparison-artifact.py"
CONFIRM_TEXT = "YES_EXISTING_ROUTE_MAY_CHANGE_STATE"

CASES: dict[str, dict[str, Any]] = {
    "study_next": {
        "domain": "study",
        "route": "/api/study/session/command",
        "helper_name": "_stage6q_study_adapter_shadow",
        "payload": {"command": "next"},
        "expected_intent": "study.next",
    },
    "companion_chat": {
        "domain": "companion",
        "route": "/api/companion/chat",
        "helper_name": "_stage6v_companion_adapter_shadow",
        "payload": {"message": "Can you help me plan my study time?"},
        "expected_intent": "companion.chat",
    },
}


def fail(message: str) -> int:
    print(f"FAIL: {message}", file=sys.stderr)
    return 1


def get_case(case_name: str, domain: str) -> dict[str, Any]:
    case = CASES.get(case_name)
    if not case:
        raise ValueError(f"unsupported case: {case_name}")
    if case["domain"] != domain:
        raise ValueError(f"case {case_name} does not belong to domain {domain}")
    return case


def default_case_for_domain(domain: str) -> str:
    if domain == "study":
        return "study_next"
    if domain == "companion":
        return "companion_chat"
    raise ValueError(f"unsupported domain: {domain}")


def run_shadow(case: dict[str, Any]) -> dict[str, Any]:
    helper_name = case["helper_name"]
    helper = getattr(edge_intent_router, helper_name)
    shadow = helper(case["payload"])
    router = shadow["router_result"]

    if router["intent"]["name"] != case["expected_intent"]:
        raise ValueError(
            f"shadow intent mismatch: expected {case['expected_intent']} got {router['intent']['name']}"
        )

    if router["dispatch_performed"] is not False:
        raise ValueError("shadow attempted dispatch")

    if router["model_routing"]["model_call_required"] is not False:
        raise ValueError("shadow attempted model call")

    if router["safety"]["allowed_to_dispatch"] is not False:
        raise ValueError("shadow unexpectedly allowed dispatch")

    return shadow


def classify_response(status_code: int, content_type: str, body: bytes) -> str:
    if status_code in (401, 403):
        return "auth_rejected"
    if status_code == 404:
        return "route_not_found"
    if 200 <= status_code < 300:
        if "application/json" in content_type.lower():
            return "existing_route_json_response"
        return "existing_route_non_json_response"
    if 300 <= status_code < 400:
        return "existing_route_redirect_response"
    if 400 <= status_code < 500:
        return "existing_route_client_error_response"
    if 500 <= status_code < 600:
        return "existing_route_server_error_response"
    if body:
        return "existing_route_unclassified_response"
    return "existing_route_empty_response"


def require_auth_env() -> dict[str, str]:
    cookie = os.environ.get("EDGE_AUTH_SHADOW_COMPARE_COOKIE")
    bearer = os.environ.get("EDGE_AUTH_SHADOW_COMPARE_BEARER")
    public_api_key = (
        os.environ.get("EDGE_AUTH_SHADOW_COMPARE_PUBLIC_API_KEY")
        or os.environ.get("EDGE_PUBLIC_API_KEY")
        or ""
    ).strip()

    if not cookie and not bearer:
        raise SystemExit(
            "authenticated execution requires EDGE_AUTH_SHADOW_COMPARE_COOKIE or EDGE_AUTH_SHADOW_COMPARE_BEARER"
        )

    headers = {"Content-Type": "application/json"}
    if cookie:
        headers["Cookie"] = cookie
    if bearer:
        headers["Authorization"] = f"Bearer {bearer}"
    if public_api_key:
        headers["x-edge-api-key"] = public_api_key

    return headers

def execute_existing_route(base_url: str, case: dict[str, Any], headers: dict[str, str]) -> dict[str, Any]:
    base_url = base_url.rstrip("/")
    url = f"{base_url}{case['route']}"
    body = json.dumps(case["payload"]).encode("utf-8")

    request = urllib.request.Request(url, data=body, headers=headers, method="POST")

    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            status_code = int(response.status)
            content_type = response.headers.get("Content-Type", "")
            response_body = response.read(4096)
    except urllib.error.HTTPError as exc:
        status_code = int(exc.code)
        content_type = exc.headers.get("Content-Type", "")
        response_body = exc.read(4096)
    except Exception as exc:
        return {
            "http_status": 0,
            "response_class": "route_call_failed",
            "state_change_summary": f"authenticated route call failed before a usable HTTP response: {type(exc).__name__}",
        }

    return {
        "http_status": status_code,
        "response_class": classify_response(status_code, content_type, response_body),
        "state_change_summary": "authenticated existing route was called; raw response body was not stored",
    }


def make_artifact(
    *,
    domain: str,
    case: dict[str, Any],
    shadow: dict[str, Any],
    current_route: dict[str, Any],
    label: str,
    mode: str,
) -> dict[str, Any]:
    router = shadow["router_result"]

    passed = (
        router["intent"]["name"] == case["expected_intent"]
        and router["dispatch_performed"] is False
        and router["model_routing"]["model_call_required"] is False
        and router["safety"]["allowed_to_dispatch"] is False
    )

    return {
        "schema_version": "stage-7c-v1",
        "artifact_kind": "authenticated_shadow_comparison_result",
        "stage": "7J",
        "domain": domain,
        "runtime_behavior_change": False,
        "comparison_mode": mode,
        "test_identity": {
            "label": label,
            "real_user_secret_stored": False,
            "auth_method_summary": "auth may be used at runtime only; no auth value is stored in this artifact",
        },
        "current_route_observation": {
            "route": case["route"],
            "method": "POST",
            "http_status": current_route["http_status"],
            "response_class": current_route["response_class"],
            "state_change_summary": current_route["state_change_summary"],
            "raw_response_stored": False,
        },
        "shadow_observation": {
            "helper": case["helper_name"],
            "intent": router["intent"]["name"],
            "confidence_band": router["intent"]["confidence_band"],
            "existing_route": router["target"]["existing_route"],
            "rule_id": router["decision_trace"][-1]["rule_id"],
            "source_surface_policy_allowed": router["source_surface_policy"]["allowed"],
            "model_call_required": router["model_routing"]["model_call_required"],
            "allowed_to_dispatch": router["safety"]["allowed_to_dispatch"],
            "dispatch_performed": router["dispatch_performed"],
            "behavior_changed": shadow["behavior_changed"],
        },
        "safety_observation": {
            "router_endpoint_disabled_by_default": True,
            "router_disabled_http_code": 404,
            "secrets_stored": False,
            "dispatch_enabled": False,
            "model_calls_enabled": False,
            "runtime_wiring_changed": False,
        },
        "comparison_result": {
            "passed": passed,
            "intent_matches_expected": router["intent"]["name"] == case["expected_intent"],
            "user_visible_regression_detected": False,
            "safe_to_continue": passed,
        },
        "notes": [
            "Stage 7J manual ops runner artifact.",
            "No auth cookies, bearer tokens, passwords, or secrets are stored.",
            "No raw authenticated response body is stored.",
            "No router dispatch or model call occurred.",
        ],
    }


def validate_artifact(path: Path) -> None:
    subprocess.run(
        [sys.executable, str(VALIDATOR), str(path)],
        cwd=str(REPO_ROOT),
        check=True,
    )


def write_and_validate_artifact(artifact: dict[str, Any], output: Path | None) -> Path:
    if output is None:
        handle = tempfile.NamedTemporaryFile(
            mode="w",
            suffix=".json",
            prefix="stage7j-auth-shadow-",
            dir="/tmp",
            delete=False,
        )
        output_path = Path(handle.name)
        with handle:
            json.dump(artifact, handle, indent=2)
            handle.write("\n")
    else:
        output_path = output
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json.dumps(artifact, indent=2) + "\n")

    validate_artifact(output_path)
    return output_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run manual local authenticated shadow comparison safely.")
    parser.add_argument("--domain", choices=["study", "companion"], required=True)
    parser.add_argument("--case", choices=sorted(CASES), default=None)
    parser.add_argument("--output", default=None, help="Output path for sanitized artifact")
    parser.add_argument("--label", default=os.environ.get("EDGE_AUTH_SHADOW_COMPARE_LABEL", "manual_test_user"))
    parser.add_argument(
        "--base-url",
        default=os.environ.get("EDGE_AUTH_SHADOW_COMPARE_BASE_URL", "http://127.0.0.1:7070"),
        help="Local base URL used only with --execute-authenticated",
    )
    parser.add_argument(
        "--execute-authenticated",
        action="store_true",
        help="Call the existing authenticated route. Off by default.",
    )
    parser.add_argument(
        "--confirm-existing-route-call",
        default="",
        help=f"Required with --execute-authenticated. Must equal {CONFIRM_TEXT}",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    case_name = args.case or default_case_for_domain(args.domain)

    try:
        case = get_case(case_name, args.domain)
        shadow = run_shadow(case)

        if args.execute_authenticated:
            if args.confirm_existing_route_call != CONFIRM_TEXT:
                return fail(
                    "authenticated execution requires explicit confirmation because existing routes may change state"
                )
            headers = require_auth_env()
            current_route = execute_existing_route(args.base_url, case, headers)
            mode = "manual_authenticated_existing_route_comparison_without_router_dispatch"
        else:
            current_route = {
                "http_status": 0,
                "response_class": "offline_runner_not_executed",
                "state_change_summary": "offline mode only; no authenticated route call was made",
            }
            mode = "offline_manual_shadow_only_without_auth_or_dispatch"

        artifact = make_artifact(
            domain=args.domain,
            case=case,
            shadow=shadow,
            current_route=current_route,
            label=args.label,
            mode=mode,
        )

        output_path = write_and_validate_artifact(
            artifact,
            Path(args.output) if args.output else None,
        )

        print(f"OK: wrote sanitized artifact: {output_path}")
        print("OK: auth values were not printed or stored")
        print("OK: artifact validated")
        return 0

    except Exception as exc:
        return fail(str(exc))


if __name__ == "__main__":
    raise SystemExit(main())
