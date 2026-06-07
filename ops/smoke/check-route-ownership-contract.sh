#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
import importlib.util
import os
from pathlib import Path

root = Path.cwd()

errors = []

def require(condition, message):
    if not condition:
        errors.append(message)

def read_text(path):
    p = root / path
    require(p.exists(), f"Missing required route ownership file: {path}")
    if not p.exists():
        return ""
    return p.read_text(errors="replace")

wrapper_path = root / "frontend/wrapper-ui/dev_server.py"
require(wrapper_path.exists(), "Missing frontend/wrapper-ui/dev_server.py")

os.environ.setdefault("EDGE_CONTROLLER_URL", "http://controller.local")
os.environ.setdefault("EDGE_PUBLIC_GATEWAY_URL", "http://gateway.local")
os.environ.setdefault("CT101_API", "http://ct101-api.local")
os.environ.setdefault("CT101_FRONTEND", "http://ct101-frontend.local")
os.environ.setdefault("WRAPPER_UI_PORT", "8787")

if wrapper_path.exists():
    spec = importlib.util.spec_from_file_location("wrapper_dev_server_route_check", wrapper_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)

    def check_map(input_path, expected_backend_attr, expected_upstream):
        backend, upstream = mod.map_api(input_path)
        expected_backend = getattr(mod, expected_backend_attr)
        require(
            backend == expected_backend and upstream == expected_upstream,
            f"map_api({input_path!r}) returned {(backend, upstream)!r}; expected {(expected_backend, expected_upstream)!r}",
        )

    route_cases = [
        ("/api/me", "CONTROLLER", "/system/session/me"),
        ("/api/auth/login", "CONTROLLER", "/system/session/login"),
        ("/api/auth/register", "CONTROLLER", "/system/session/register"),
        ("/api/auth/logout", "CONTROLLER", "/system/session/logout-safe"),
        ("/api/account/credits", "CONTROLLER", "/system/account/credits"),
        ("/api/backend/study/progress", "CT101_API", "/api/study/progress"),
        ("/api/backend/companion/chat", "CT101_API", "/api/companion/chat"),
        ("/api/study/decks", "GATEWAY", "/public/study/decks"),
        ("/api/companion/context", "GATEWAY", "/public/companion/context"),
        ("/api/companion/chat", "GATEWAY", "/public/companion/chat"),
        ("/api/system/status", "GATEWAY", "/system/status"),
    ]

    for case in route_cases:
        check_map(*case)

    for route in ["/study", "/companion", "/calendar", "/profile"]:
        require(route in mod.FULL_APP_ROUTES, f"{route} missing from FULL_APP_ROUTES")

public_gateway = read_text("public_gateway.py")
for marker in [
    "/public/study/decks",
    "/public/study/progress",
    "/public/companion/context",
    "/public/companion/chat",
    "/system/status",
    "/system/pveso/boot",
]:
    require(marker in public_gateway, f"public_gateway.py missing route marker {marker}")

worker = read_text("cloudflare/edge-public-proxy/src/index.js")
for marker in [
    "mapApiPathToBackend",
    "/api/auth",
    "/api/jobs",
    "/api/study",
    "/api/companion",
    "/api/system",
]:
    require(marker in worker, f"Cloudflare worker missing route marker {marker}")

for doc_path in ["docs/public-route-map.md", "docs/route-ownership.md"]:
    doc = read_text(doc_path)
    for marker in ["wrapper", "gateway", "controller"]:
        require(marker.lower() in doc.lower(), f"{doc_path} missing ownership marker {marker}")

if errors:
    print("FAIL: route ownership contract check failed")
    for error in errors:
        print(f"  - {error}")
    raise SystemExit(1)

print("PASS: route ownership contract is consistent")
PY
