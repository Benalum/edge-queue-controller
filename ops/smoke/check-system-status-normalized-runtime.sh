#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
import edge_controller
import public_gateway


REQUIRED_FIELDS = {
    "ok",
    "checked_at",
    "overall_state",
    "nodes",
    "services",
}
INFRASTRUCTURE_IDS = {
    "controller-node",
    "server-nodes",
    "cpu-nodes",
    "gpu-nodes",
    "storage-nodes",
}
PLATFORM_IDS = {
    "backend-api",
    "frontend-wrapper",
    "queue",
    "workers",
    "power-automation",
}


def assert_normalized_shape(payload):
    missing = REQUIRED_FIELDS - set(payload)
    assert not missing, f"missing existing fields: {sorted(missing)}"

    normalized = payload.get("normalized")
    assert isinstance(normalized, dict), "normalized must be an object"
    assert "infrastructure" in normalized, "normalized.infrastructure missing"
    assert "platform" in normalized, "normalized.platform missing"

    infrastructure = normalized["infrastructure"]
    platform = normalized["platform"]
    assert isinstance(infrastructure, list), "normalized.infrastructure must be a list"
    assert isinstance(platform, list), "normalized.platform must be a list"

    infrastructure_ids = {
        item.get("id")
        for item in infrastructure
        if isinstance(item, dict)
    }
    platform_ids = {
        item.get("id")
        for item in platform
        if isinstance(item, dict)
    }

    missing_infrastructure = INFRASTRUCTURE_IDS - infrastructure_ids
    missing_platform = PLATFORM_IDS - platform_ids
    assert not missing_infrastructure, (
        f"missing infrastructure ids: {sorted(missing_infrastructure)}"
    )
    assert not missing_platform, f"missing platform ids: {sorted(missing_platform)}"


original_tcp_check = edge_controller._system_tcp_check
original_ssh_check = edge_controller._system_ssh_check
original_pct_status = edge_controller._system_pct_status
original_http_check = edge_controller._system_http_check
original_laptop_specs = edge_controller._system_laptop_specs
original_gateway_fetch = public_gateway._system_v2_fetch_json

try:
    edge_controller._system_tcp_check = lambda host, port, timeout=2: False
    edge_controller._system_ssh_check = lambda: {
        "ok": False,
        "stdout": "",
        "stderr": "smoke test: SSH disabled",
    }
    edge_controller._system_pct_status = lambda ctid: {
        "state": "offline",
        "detail": "smoke test: CT101 not queried",
    }
    edge_controller._system_http_check = lambda url, timeout=3: {
        "ok": True,
        "status_code": 200,
        "error": "",
    }
    edge_controller._system_laptop_specs = lambda: {
        "cpu": "smoke",
        "machine": "smoke",
        "os": "smoke",
        "cores": "unknown",
        "ram": "unknown",
        "root_disk": "unknown",
    }

    status_payload = edge_controller.system_status()
    assert_normalized_shape(status_payload)

    public_gateway._system_v2_fetch_json = lambda path, **kwargs: (
        200,
        status_payload,
    )

    public_payload = public_gateway._system_v2_public_payload()
    assert public_payload.get("normalized") == status_payload.get("normalized")
finally:
    edge_controller._system_tcp_check = original_tcp_check
    edge_controller._system_ssh_check = original_ssh_check
    edge_controller._system_pct_status = original_pct_status
    edge_controller._system_http_check = original_http_check
    edge_controller._system_laptop_specs = original_laptop_specs
    public_gateway._system_v2_fetch_json = original_gateway_fetch

print("PASS: normalized system status runtime shape verified")
PY
