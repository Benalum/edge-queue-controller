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

os.environ.setdefault("EDGE_CONTROLLER_URL", "http://controller.local")
os.environ.setdefault("EDGE_PUBLIC_GATEWAY_URL", "http://gateway.local")
os.environ.setdefault("CT101_API", "http://ct101-api.local")
os.environ.setdefault("CT101_FRONTEND", "http://ct101-frontend.local")
os.environ.setdefault("WRAPPER_UI_PORT", "8787")
os.environ.setdefault("EDGE_TRUSTED_PROXY_SECRET", "test-secret")

path = root / "frontend/wrapper-ui/dev_server.py"
require(path.exists(), "Missing frontend/wrapper-ui/dev_server.py")

if path.exists():
    spec = importlib.util.spec_from_file_location("wrapper_dev_server_auth_proxy_check", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)

    controller_routes = {
        "/api/me": "/system/session/me",
        "/api/auth/login": "/system/session/login",
        "/api/auth/register": "/system/session/register",
        "/api/auth/logout": "/system/session/logout-safe",
        "/api/account/credits": "/system/account/credits",
        "/api/account/credit-pools": "/system/account/credit-pools",
    }

    for public_path, upstream_path in controller_routes.items():
        backend, upstream = mod.map_api(public_path)
        require(
            backend == mod.CONTROLLER and upstream == upstream_path,
            f"{public_path} should route to controller {upstream_path}, got {(backend, upstream)}",
        )

    backend, upstream = mod.map_api("/api/backend/study/progress")
    require(
        backend == mod.CT101_API and upstream == "/api/study/progress",
        f"/api/backend/study/progress should route directly to CT101 API, got {(backend, upstream)}",
    )

    backend, upstream = mod.map_api("/api/backend/companion/chat")
    require(
        backend == mod.CT101_API and upstream == "/api/companion/chat",
        f"/api/backend/companion/chat should route directly to CT101 API, got {(backend, upstream)}",
    )

    backend, upstream = mod.map_api("/api/study/decks")
    require(
        backend == mod.GATEWAY and upstream == "/public/study/decks",
        f"/api/study/decks should route through public gateway, got {(backend, upstream)}",
    )

    backend, upstream = mod.map_api("/api/companion/context")
    require(
        backend == mod.GATEWAY and upstream == "/public/companion/context",
        f"/api/companion/context should route through public gateway, got {(backend, upstream)}",
    )

    for private_route in ["/study", "/companion", "/calendar", "/profile"]:
        require(
            private_route in mod.FULL_APP_ROUTES,
            f"{private_route} missing from FULL_APP_ROUTES",
        )

    source = path.read_text(errors="replace")

    required_markers = [
        # AUTH_ROUTE_COOKIE_V1 was an older marker name. The actual contract is
        # covered above by map_api() route assertions for /api/auth/* and /api/me.
        "BACKEND_COOKIE_TO_BEARER_ORIGINAL_PATH_V1",
        "auth_source_path = original_path or upstream_path",
        'auth_source_path.startswith("/api/backend/")',
        "EDGE_USER_HEADER_BRIDGE_V1",
        "edgeStudyToken",
        "Authorization",
        "X-Edge-Auth-Secret",
        "X-Edge-User-Id",
        "X-Edge-User-Email",
        "X-Edge-User-Is-Admin",
        "EDGE_TRUSTED_PROXY_SECRET",
    ]

    for marker in required_markers:
        require(marker in source, f"frontend/wrapper-ui/dev_server.py missing marker {marker}")

    require(
        'auth_bridge_path.startswith("/api/backend/")' in source,
        "Trusted edge headers must only be injected for /api/backend/* requests",
    )

    require(
        'if not EDGE_TRUSTED_PROXY_SECRET:' in source,
        "Trusted edge header injection must require EDGE_TRUSTED_PROXY_SECRET",
    )

    require(
        'headers["Authorization"] = f"Bearer {token}"' in source,
        "Wrapper must convert edgeStudyToken cookie to Authorization bearer for CT101 backend requests",
    )

    require(
        'upstream_path.startswith("/api/backend/")' not in source,
        "Wrapper must not check rewritten upstream_path for /api/backend/* cookie-to-bearer auth",
    )

if errors:
    print("FAIL: wrapper auth/proxy contract check failed")
    for error in errors:
        print(f"  - {error}")
    raise SystemExit(1)

print("PASS: wrapper auth/proxy contract is consistent")
PY
