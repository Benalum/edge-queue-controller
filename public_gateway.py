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


# ============================================================
# SYSTEM_PUBLIC_ADMIN_STATUS_V2
# Public users see API health only.
# Admin users can see full infrastructure details.
# ============================================================

import os as _system_v2_os
import json as _system_v2_json
import urllib.request as _system_v2_request
import urllib.error as _system_v2_error
from fastapi.responses import JSONResponse as _SystemV2JSONResponse

_SYSTEM_V2_CONTROLLER_BASE = _system_v2_os.getenv(
    "SYSTEM_CONTROLLER_BASE",
    "http://127.0.0.1:7070"
).rstrip("/")


def _system_v2_fetch_json(path, method="GET", body=None, headers=None, timeout=15):
    url = _SYSTEM_V2_CONTROLLER_BASE + path
    req_headers = {
        "User-Agent": "edge-public-gateway-system-v2/1.0",
    }

    if headers:
        for k, v in headers.items():
            if v:
                req_headers[k] = v

    data = None
    if body is not None:
        data = _system_v2_json.dumps(body).encode("utf-8")
        req_headers["Content-Type"] = "application/json"

    req = _system_v2_request.Request(
        url,
        data=data,
        headers=req_headers,
        method=method,
    )

    try:
        with _system_v2_request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            try:
                payload = _system_v2_json.loads(raw)
            except Exception:
                payload = {"ok": False, "detail": raw}
            return resp.status, payload
    except _system_v2_error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace")
        try:
            payload = _system_v2_json.loads(raw)
        except Exception:
            payload = {"ok": False, "detail": raw}
        return e.code, payload
    except Exception as e:
        return 502, {
            "ok": False,
            "detail": f"Controller fetch failed: {e}",
            "path": path,
        }


def _system_v2_public_api_state(service, fallback="planned"):
    if not service:
        return fallback

    state = service.get("state") or fallback
    detail = str(service.get("detail") or "").lower()

    # 401/403 means the API exists but is protected.
    if "401" in detail or "403" in detail or "unauthorized" in detail:
        return "online"

    return state


def _system_v2_public_api_detail(service, fallback):
    if not service:
        return fallback

    detail = str(service.get("detail") or "")

    if "401" in detail or "403" in detail or "unauthorized" in detail.lower():
        return "Protected API route is responding."

    return detail or fallback


def _system_v2_public_payload():
    status_code, full = _system_v2_fetch_json("/system/status")

    if status_code >= 500 or not isinstance(full, dict):
        return {
            "ok": False,
            "overall_state": "unknown",
            "checked_at": None,
            "apis": [
                {
                    "id": "study-api",
                    "name": "Study API",
                    "state": "unknown",
                    "detail": "Could not reach controller.",
                },
                {
                    "id": "companion-api",
                    "name": "Companion API",
                    "state": "planned",
                    "detail": "Companion API will track chat, grading, and context.",
                },
                {
                    "id": "profile-api",
                    "name": "Profile API",
                    "state": "planned",
                    "detail": "Profile API will track preferences and permissions.",
                },
                {
                    "id": "calendar-api",
                    "name": "Calendar API",
                    "state": "planned",
                    "detail": "Calendar API will track scheduling and reminders.",
                },
                {
                    "id": "images-api",
                    "name": "Images API",
                    "state": "planned",
                    "detail": "Images API will support future ComfyUI-backed image generation.",
                },
            ],
            "services": [],
        }

    services = full.get("services") or []
    by_id = {s.get("id"): s for s in services if isinstance(s, dict)}
    study = by_id.get("study-api")

    apis = [
        {
            "id": "study-api",
            "name": "Study API",
            "state": _system_v2_public_api_state(study, "unknown"),
            "detail": _system_v2_public_api_detail(
                study,
                "Decks, cards, reviews, stats, and study progress."
            ),
        },
        {
            "id": "companion-api",
            "name": "Companion API",
            "state": "planned",
            "detail": "Companion chat, grading, and context API.",
        },
        {
            "id": "profile-api",
            "name": "Profile API",
            "state": "planned",
            "detail": "Profile, preferences, permissions, and user settings API.",
        },
        {
            "id": "calendar-api",
            "name": "Calendar API",
            "state": "planned",
            "detail": "Calendar, reminders, deadlines, and scheduling API.",
        },
        {
            "id": "images-api",
            "name": "Images API",
            "state": "planned",
            "detail": "Future ComfyUI-backed image generation for user-specific companion images.",
        },
    ]

    active_api_states = [
        api["state"]
        for api in apis
        if api["state"] != "planned"
    ]

    if any(s == "error" for s in active_api_states):
        overall = "error"
    elif any(s in ("offline", "degraded", "unknown") for s in active_api_states):
        overall = "degraded"
    else:
        overall = "online"

    return {
        "ok": True,
        "checked_at": full.get("checked_at"),
        "overall_state": overall,
        "apis": apis,
        # Keep services alias so older frontend code can still read it.
        "services": apis,
    }


def _system_v2_admin_emails():
    raw = _system_v2_os.getenv("ADMIN_EMAILS", "")
    return {
        item.strip().lower()
        for item in raw.split(",")
        if item.strip()
    }


def _system_v2_extract_email(me_payload):
    if not isinstance(me_payload, dict):
        return ""

    user = me_payload.get("user")
    if isinstance(user, dict):
        return str(user.get("email") or user.get("username") or "").lower()

    return str(
        me_payload.get("email") or
        me_payload.get("username") or
        ""
    ).lower()


def _system_v2_is_admin(request):
    # DB role/is_admin is the primary source of truth.
    # ADMIN_EMAILS is only an optional bootstrap/recovery fallback.
    admin_emails = _system_v2_admin_emails()

    authorization = request.headers.get("Authorization") or ""
    if not authorization:
        return False, ""

    forward_headers = {
        "Authorization": authorization,
    }

    edge_key = request.headers.get("X-Edge-Api-Key")
    if edge_key:
        forward_headers["X-Edge-Api-Key"] = edge_key

    # Try the likely account/session endpoints used by the controller.
    # Different parts of this project have used slightly different auth paths.
    me = None
    email = ""

    for me_path in ("/system/session/me", "/system/account/me", "/me", "/auth/me", "/public/me"):
        status_code, payload = _system_v2_fetch_json(
            me_path,
            method="GET",
            headers=forward_headers,
            timeout=8,
        )

        if status_code == 200:
            me = payload
            email = _system_v2_extract_email(me)

            user = payload.get("user") if isinstance(payload, dict) else None
            if isinstance(user, dict):
                if user.get("is_admin") is True or str(user.get("role") or "").lower() == "admin":
                    return True, email

            if email:
                break

    if not email:
        return False, ""

    # Fallback/bootstrap admin list.
    return email in admin_emails, email


@app.middleware("http")
async def _system_public_admin_status_v2(request, call_next):
    path = request.url.path
    method = request.method.upper()

    if method == "GET" and path in ("/system/status", "/system/public-status"):
        return _SystemV2JSONResponse(_system_v2_public_payload(), status_code=200)

    if method == "GET" and path == "/system/admin-status":
        is_admin, email = _system_v2_is_admin(request)

        if not is_admin:
            return _SystemV2JSONResponse(
                {
                    "ok": False,
                    "detail": "Admin access required.",
                    "email": email or None,
                },
                status_code=403,
            )

        status_code, full = _system_v2_fetch_json("/system/status")
        if isinstance(full, dict):
            full["admin"] = True
            full["admin_email"] = email
        return _SystemV2JSONResponse(full, status_code=status_code)

    return await call_next(request)


# ============================================================
# Public ad reward route guard
# Rewarded-ad routes stay blocked publicly until a real provider
# verification flow is implemented and explicitly enabled.
# Local dev server can still call controller /system/ads/* directly.
# ============================================================

@app.middleware("http")
async def _block_public_ad_reward_routes_until_enabled(request, call_next):
    path = request.url.path

    if path.startswith("/system/ads/"):
        enabled = str(_system_v2_os.getenv("ENABLE_PUBLIC_AD_REWARD_ROUTES", "false")).strip().lower() in (
            "1",
            "true",
            "yes",
            "on",
        )

        if not enabled:
            return _SystemV2JSONResponse(
                {
                    "ok": False,
                    "detail": "Rewarded ads are not enabled on the public gateway yet.",
                },
                status_code=404,
            )

    return await call_next(request)

