import os
import re

import httpx
from fastapi import FastAPI, Request
from fastapi.responses import Response, JSONResponse


BACKEND_BASE_URL = os.getenv("EDGE_PUBLIC_GATEWAY_BACKEND", "http://127.0.0.1:7070").rstrip("/")
REQUEST_TIMEOUT_SECONDS = float(os.getenv("EDGE_PUBLIC_GATEWAY_TIMEOUT_SECONDS", "300"))

app = FastAPI(title="Edge Queue Public Gateway")


def is_allowed_public_route(method: str, path: str) -> bool:
    method = method.upper()

    if method == "GET" and path == "/public/status":
        return True

    if method == "POST" and path == "/public/jobs":
        return True

    if method == "GET" and path == "/public/jobs":
        return True

    if method == "GET" and re.fullmatch(r"/public/jobs/[0-9]+", path):
        return True

    if method == "POST" and path in {"/public/auth/register", "/public/auth/login", "/public/auth/logout"}:
        return True

    if method == "GET" and path == "/public/me":
        return True

    if method in {"GET", "POST"} and path == "/public/study/decks":
        return True

    if method in {"GET", "POST"} and re.fullmatch(r"/public/study/decks/[0-9]+/cards", path):
        return True

    if method == "POST" and re.fullmatch(r"/public/study/cards/[0-9]+/reviews", path):
        return True

    if method == "GET" and path == "/public/study/progress":
        return True

    if method == "GET" and re.fullmatch(r"/public/study/decks/[0-9]+/card-stats", path):
        return True

    if method == "GET" and re.fullmatch(r"/public/study/decks/[0-9]+/review-queue", path):
        return True

    if method == "POST" and path == "/public/companion/study/grade":
        return True

    if method == "GET" and path == "/public/companion/context":
        return True

    if method == "POST" and path == "/public/companion/chat":
        return True



    return False


@app.get("/gateway/health")
async def gateway_health():
    return {
        "ok": True,
        "gateway": "edge-queue-public-gateway",
        "backend": BACKEND_BASE_URL,
    }


@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"])
async def gateway_proxy(path: str, request: Request):
    request_path = "/" + path

    if not is_allowed_public_route(request.method, request_path):
        return JSONResponse(
            status_code=404,
            content={
                "ok": False,
                "detail": "Not found.",
            },
        )

    query = request.url.query
    target_url = f"{BACKEND_BASE_URL}{request_path}"
    if query:
        target_url += f"?{query}"

    body = await request.body()

    forwarded_headers = {}

    for header_name in [
        "content-type",
        "accept",
        "x-edge-api-key",
        "authorization",
    ]:
        value = request.headers.get(header_name)
        if value:
            forwarded_headers[header_name] = value

    async with httpx.AsyncClient(timeout=REQUEST_TIMEOUT_SECONDS) as client:
        upstream = await client.request(
            method=request.method,
            url=target_url,
            headers=forwarded_headers,
            content=body,
        )

    response_headers = {}
    content_type = upstream.headers.get("content-type")
    if content_type:
        response_headers["content-type"] = content_type

    return Response(
        content=upstream.content,
        status_code=upstream.status_code,
        headers=response_headers,
    )

# ============================================================
# System status / power proxy routes
# Allows Cloudflare Worker:
#   /api/system/status -> edge-api /system/status -> controller /system/status
#   /api/system/pveso/boot -> edge-api /system/pveso/boot -> controller /system/pveso/boot
# ============================================================

import os as _system_proxy_os
import json as _system_proxy_json
import urllib.request as _system_proxy_request
import urllib.error as _system_proxy_error
from fastapi import Request as _SystemProxyRequest, Body as _SystemProxyBody
from fastapi.responses import JSONResponse as _SystemProxyJSONResponse

_SYSTEM_CONTROLLER_BASE = _system_proxy_os.getenv(
    "SYSTEM_CONTROLLER_BASE",
    "http://127.0.0.1:7070"
).rstrip("/")


def _system_proxy_json_request(path, method="GET", body=None):
    url = _SYSTEM_CONTROLLER_BASE + path

    data = None
    headers = {
        "User-Agent": "public-gateway-system-proxy/1.0",
    }

    if body is not None:
        data = _system_proxy_json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = _system_proxy_request.Request(
        url,
        data=data,
        headers=headers,
        method=method,
    )

    try:
        with _system_proxy_request.urlopen(req, timeout=15) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            try:
                payload = _system_proxy_json.loads(raw)
            except Exception:
                payload = {"ok": False, "detail": raw}
            return _SystemProxyJSONResponse(payload, status_code=resp.status)
    except _system_proxy_error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace")
        try:
            payload = _system_proxy_json.loads(raw)
        except Exception:
            payload = {"ok": False, "detail": raw}
        return _SystemProxyJSONResponse(payload, status_code=e.code)
    except Exception as e:
        return _SystemProxyJSONResponse(
            {
                "ok": False,
                "detail": f"System proxy failed: {e}",
                "controller_base": _SYSTEM_CONTROLLER_BASE,
                "path": path,
            },
            status_code=502,
        )


@app.get("/system/status")
def public_system_status():
    return _system_proxy_json_request("/system/status", method="GET")


@app.post("/system/pveso/boot")
async def public_system_boot_pveso(payload: dict = _SystemProxyBody(default={})):
    return _system_proxy_json_request(
        "/system/pveso/boot",
        method="POST",
        body=payload,
    )


# ============================================================
# System status / power proxy routes
# edge-api.alexhartel.com/system/status -> controller /system/status
# ============================================================

import os as _system_proxy_os
import json as _system_proxy_json
import urllib.request as _system_proxy_request
import urllib.error as _system_proxy_error
from fastapi import Body as _SystemProxyBody
from fastapi.responses import JSONResponse as _SystemProxyJSONResponse

_SYSTEM_CONTROLLER_BASE = _system_proxy_os.getenv(
    "SYSTEM_CONTROLLER_BASE",
    "http://127.0.0.1:7070"
).rstrip("/")


def _system_proxy_json_request(path, method="GET", body=None):
    url = _SYSTEM_CONTROLLER_BASE + path

    data = None
    headers = {
        "User-Agent": "public-gateway-system-proxy/1.0",
    }

    if body is not None:
        data = _system_proxy_json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = _system_proxy_request.Request(
        url,
        data=data,
        headers=headers,
        method=method,
    )

    try:
        with _system_proxy_request.urlopen(req, timeout=15) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            try:
                payload = _system_proxy_json.loads(raw)
            except Exception:
                payload = {"ok": False, "detail": raw}
            return _SystemProxyJSONResponse(payload, status_code=resp.status)

    except _system_proxy_error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace")
        try:
            payload = _system_proxy_json.loads(raw)
        except Exception:
            payload = {"ok": False, "detail": raw}
        return _SystemProxyJSONResponse(payload, status_code=e.code)

    except Exception as e:
        return _SystemProxyJSONResponse(
            {
                "ok": False,
                "detail": f"System proxy failed: {e}",
                "controller_base": _SYSTEM_CONTROLLER_BASE,
                "path": path,
            },
            status_code=502,
        )


@app.get("/system/status")
def public_system_status():
    return _system_proxy_json_request("/system/status", method="GET")


@app.post("/system/pveso/boot")
async def public_system_boot_pveso(payload: dict = _SystemProxyBody(default={})):
    return _system_proxy_json_request(
        "/system/pveso/boot",
        method="POST",
        body=payload,
    )



# SYSTEM_PROXY_MIDDLEWARE_BYPASS_V1
# This catches system routes BEFORE any catch-all public gateway route.
# Worker path:
#   /api/system/status -> /system/status
#   /api/system/pveso/boot -> /system/pveso/boot

import os as _system_mw_os
import json as _system_mw_json
import urllib.request as _system_mw_request
import urllib.error as _system_mw_error
from fastapi.responses import JSONResponse as _SystemMwJSONResponse

_SYSTEM_MW_CONTROLLER_BASE = _system_mw_os.getenv(
    "SYSTEM_CONTROLLER_BASE",
    "http://127.0.0.1:7070"
).rstrip("/")


def _system_mw_expected_key():
    # Try the names used across our gateway/controller/worker setup.
    # The correct one depends on how the systemd service and .env were created.
    for name in (
        "EDGE_PUBLIC_API_KEY",
        "PUBLIC_API_KEY",
        "EDGE_API_KEY",
        "PUBLIC_GATEWAY_API_KEY",
        "PUBLIC_GATEWAY_TOKEN",
        "EDGE_QUEUE_PUBLIC_API_KEY",
        "EDGE_QUEUE_API_KEY",
        "GATEWAY_API_KEY",
        "GATEWAY_TOKEN",
    ):
        value = _system_mw_os.getenv(name)
        if value:
            return value
    return ""


def _system_mw_proxy(path, method="GET", body=None):
    url = _SYSTEM_MW_CONTROLLER_BASE + path

    data = None
    headers = {
        "User-Agent": "edge-public-gateway-system-middleware/1.0",
    }

    if body is not None:
        data = _system_mw_json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = _system_mw_request.Request(
        url,
        data=data,
        headers=headers,
        method=method,
    )

    try:
        with _system_mw_request.urlopen(req, timeout=15) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            try:
                payload = _system_mw_json.loads(raw)
            except Exception:
                payload = {"ok": False, "detail": raw}

            return _SystemMwJSONResponse(payload, status_code=resp.status)

    except _system_mw_error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace")
        try:
            payload = _system_mw_json.loads(raw)
        except Exception:
            payload = {"ok": False, "detail": raw}

        return _SystemMwJSONResponse(payload, status_code=e.code)

    except Exception as e:
        return _SystemMwJSONResponse(
            {
                "ok": False,
                "detail": f"System middleware proxy failed: {e}",
                "controller_base": _SYSTEM_MW_CONTROLLER_BASE,
                "path": path,
            },
            status_code=502,
        )


@app.middleware("http")
async def _system_proxy_middleware_bypass_v1(request, call_next):
    path = request.url.path
    method = request.method.upper()

    is_system_status = path == "/system/status" and method == "GET"
    is_system_boot = path == "/system/pveso/boot" and method == "POST"

    if not is_system_status and not is_system_boot:
        return await call_next(request)

    # System status is safe to expose as public-read because it only returns
    # friendly machine/service states, not passwords, tokens, SSH keys, or commands.
    if is_system_status:
        return _system_mw_proxy("/system/status", method="GET")

    # Boot/power actions must stay protected.
    # If no gateway secret is loaded, keep the boot route hidden/blocked.
    expected_key = _system_mw_expected_key()
    provided_key = request.headers.get("X-Edge-Api-Key") or ""

    if not expected_key:
        return _SystemMwJSONResponse(
            {"ok": False, "detail": "Boot route is not enabled until gateway secret is configured."},
            status_code=403,
        )

    if provided_key != expected_key:
        return _SystemMwJSONResponse(
            {"ok": False, "detail": "Not found."},
            status_code=404,
        )

    try:
        payload = await request.json()
        if not isinstance(payload, dict):
            payload = {}
    except Exception:
        payload = {}

    return _system_mw_proxy("/system/pveso/boot", method="POST", body=payload)

