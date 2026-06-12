#!/usr/bin/env python3
"""Validate authenticated shadow comparison artifacts.

This utility is offline-only.

It does not authenticate.
It does not call HTTP routes.
It does not dispatch router actions.
It does not call models.
It does not mutate Study, Companion, Chat, Calendar, Profile, admin, power, or system state.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


SECRET_PATTERNS = {
    "private_key_block": re.compile(r"BEGIN [A-Z ]*PRIVATE KEY"),
    "openai_like_secret": re.compile(r"\bsk-[A-Za-z0-9_-]{20,}\b"),
    "github_pat": re.compile(r"\bgh[pousr]_[A-Za-z0-9_]{20,}\b"),
    "slack_token": re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{20,}\b"),
    "tailscale_key": re.compile(r"\btskey-[A-Za-z0-9_-]{20,}\b"),
    "aws_access_key": re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    "jwt_like_value": re.compile(r"\beyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"),
    "bearer_value": re.compile(r"Authorization:\s*Bearer\s+\S+", re.IGNORECASE),
    "cookie_value": re.compile(r"Cookie:\s*\S+", re.IGNORECASE),
    "session_assignment": re.compile(r"\b(session|sessionid|token|auth_token)=\S+", re.IGNORECASE),
}


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text())
    except Exception as exc:
        raise ValueError(f"{path}: failed to read JSON: {exc}") from exc


def walk_strings(value: Any, path: str = "$"):
    if isinstance(value, str):
        yield path, value
    elif isinstance(value, dict):
        for key, nested in value.items():
            yield from walk_strings(nested, f"{path}.{key}")
    elif isinstance(value, list):
        for idx, nested in enumerate(value):
            yield from walk_strings(nested, f"{path}[{idx}]")


def require(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def validate_no_secret_like_values(artifact: dict[str, Any], errors: list[str]) -> None:
    for path, text in walk_strings(artifact):
        for name, pattern in SECRET_PATTERNS.items():
            if pattern.search(text):
                errors.append(f"secret-like value detected at {path}: {name}")


def validate_artifact(schema: dict[str, Any], artifact: dict[str, Any], artifact_path: Path) -> list[str]:
    errors: list[str] = []

    required_top = schema.get("required_top_level_fields", [])
    for field in required_top:
        require(field in artifact, f"{artifact_path}: missing top-level field: {field}", errors)

    if errors:
        validate_no_secret_like_values(artifact, errors)
        return errors

    require(artifact.get("schema_version") == schema.get("schema_version"), f"{artifact_path}: invalid schema_version", errors)
    require(artifact.get("artifact_kind") == schema.get("artifact_kind"), f"{artifact_path}: invalid artifact_kind", errors)
    require(artifact.get("runtime_behavior_change") is False, f"{artifact_path}: runtime_behavior_change must be false", errors)

    supported_domains = set(schema.get("supported_domains", []))
    domain = artifact.get("domain")
    require(domain in supported_domains, f"{artifact_path}: unsupported domain: {domain}", errors)

    domain_contracts = schema.get("domain_contracts", {})
    domain_contract = domain_contracts.get(domain, {})

    current = artifact.get("current_route_observation", {})
    shadow = artifact.get("shadow_observation", {})
    safety = artifact.get("safety_observation", {})
    identity = artifact.get("test_identity", {})
    result = artifact.get("comparison_result", {})

    field_contract = schema.get("field_contract", {})

    for field in field_contract.get("test_identity", {}).get("required_fields", []):
        require(field in identity, f"{artifact_path}: missing test_identity.{field}", errors)

    for field in field_contract.get("current_route_observation", {}).get("required_fields", []):
        require(field in current, f"{artifact_path}: missing current_route_observation.{field}", errors)

    for field in field_contract.get("shadow_observation", {}).get("required_fields", []):
        require(field in shadow, f"{artifact_path}: missing shadow_observation.{field}", errors)

    for field in field_contract.get("safety_observation", {}).get("required_fields", []):
        require(field in safety, f"{artifact_path}: missing safety_observation.{field}", errors)

    for field in field_contract.get("comparison_result", {}).get("required_fields", []):
        require(field in result, f"{artifact_path}: missing comparison_result.{field}", errors)

    require(identity.get("real_user_secret_stored") is False, f"{artifact_path}: real_user_secret_stored must be false", errors)
    require(current.get("raw_response_stored") is False, f"{artifact_path}: raw_response_stored must be false", errors)

    allowed_routes = set(domain_contract.get("allowed_routes", []))
    require(current.get("route") in allowed_routes, f"{artifact_path}: route not allowed for domain: {current.get('route')}", errors)

    require(
        shadow.get("helper") == domain_contract.get("shadow_helper"),
        f"{artifact_path}: shadow helper does not match domain contract",
        errors,
    )

    expected_safe_intents = set(domain_contract.get("expected_safe_intents", []))
    require(shadow.get("intent") in expected_safe_intents, f"{artifact_path}: unsafe or unknown intent: {shadow.get('intent')}", errors)

    for field in field_contract.get("shadow_observation", {}).get("required_false_fields", []):
        require(shadow.get(field) is False, f"{artifact_path}: shadow_observation.{field} must be false", errors)

    required_safety = field_contract.get("safety_observation", {}).get("required_values", {})
    for field, expected in required_safety.items():
        require(safety.get(field) == expected, f"{artifact_path}: safety_observation.{field} must be {expected}", errors)

    require(result.get("user_visible_regression_detected") is False, f"{artifact_path}: user_visible_regression_detected must be false", errors)

    notes = artifact.get("notes")
    require(isinstance(notes, list), f"{artifact_path}: notes must be a list", errors)

    validate_no_secret_like_values(artifact, errors)

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate authenticated shadow comparison artifacts.")
    parser.add_argument("artifacts", nargs="+", help="Artifact JSON files to validate")
    parser.add_argument(
        "--schema",
        default="docs/generated/stage-7c-authenticated-shadow-comparison-artifact-schema.json",
        help="Path to Stage 7C artifact schema JSON",
    )
    args = parser.parse_args()

    schema_path = Path(args.schema)
    schema = load_json(schema_path)

    all_errors: list[str] = []
    for artifact_name in args.artifacts:
        artifact_path = Path(artifact_name)
        artifact = load_json(artifact_path)
        errors = validate_artifact(schema, artifact, artifact_path)
        if errors:
            all_errors.extend(errors)
        else:
            print(f"OK: artifact valid: {artifact_path}")

    if all_errors:
        print("FAIL: artifact validation failed")
        for error in all_errors:
            print(f"- {error}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
