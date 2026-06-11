from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse
from http.cookies import SimpleCookie
import os
import mimetypes
import sys
import re
import json
import urllib.error
import urllib.request

UNIFIED_SHELL_ROUTES = {
    "/",
    "/login",
    "/register",
    "/study",
    "/chat",
    "/companion",
    "/calendar",
    "/profile",
    "/credits",
    "/admin",
    "/support",
    "/system",
}

def _is_unified_shell_route(path):
    clean = path.split("?", 1)[0].rstrip("/") or "/"
    return clean in UNIFIED_SHELL_ROUTES



CONTROLLER = os.getenv("EDGE_CONTROLLER_URL", "http://127.0.0.1:7070")
GATEWAY = os.getenv("EDGE_PUBLIC_GATEWAY_URL", "http://127.0.0.1:7071")
CT101_FRONTEND = os.getenv("CT101_FRONTEND", "http://100.88.245.33:3010")
CT101_API = os.getenv("CT101_API", "http://100.88.245.33:8088")
PORT = int(os.getenv("WRAPPER_UI_PORT", "8787"))
EDGE_TRUSTED_PROXY_SECRET = os.getenv("EDGE_TRUSTED_PROXY_SECRET", "")
EDGE_PUBLIC_API_KEY = os.getenv("EDGE_PUBLIC_API_KEY", "")
WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED = os.getenv("WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED", "").strip().lower() in {"1", "true", "yes", "on"}

# STAGE_5H3_WRAPPER_REPO_ROOT_IMPORT_PATH_V1
# dev_server.py runs from frontend/wrapper-ui, so add the repo root before
# server-side fallback imports like edge_modules.* are needed.
REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

FULL_APP_ROUTES = {"/study", "/chat", "/companion", "/calendar", "/profile"}
WRAPPER_ROUTES = {"/", "/study", "/chat", "/companion", "/calendar", "/profile", "/system"}


def map_api(path):
    # RESTORE_CONTROLLER_AUTH_PRIORITY_V1
    # Wrapper login/admin/credits currently belong to the laptop controller.
    # Keep these before any CT101 routing.
    controller_auth_exact = {
        "/api/me": "/system/session/me",
        "/api/auth/login": "/system/session/login",
        "/api/auth/me": "/system/session/me",
        "/api/auth/register": "/system/session/register",
        "/api/auth/logout": "/system/session/logout-safe",
        # AUTH_EXTRA_CONTROLLER_ROUTES_V1
        # Keep browser auth flows on the controller instead of falling through
        # to the public gateway's generic /api -> / path rewrite.
        "/api/auth/forgot-password": "/system/session/forgot-password",
        "/api/auth/reset-password": "/system/session/reset-password",
        "/api/auth/change-password": "/system/session/change-password",
        "/api/auth/verify-email": "/api/auth/verify-email",
        "/api/auth/resend-verification": "/api/auth/resend-verification",
        "/api/account/credits": "/system/account/credits",
        "/api/account/credit-pools": "/system/account/credit-pools",
    }

    if path in controller_auth_exact:
        return CONTROLLER, controller_auth_exact[path]

    # STAGE_5G2_LAPTOP_QUEUED_CHAT_CONTROLLER_OWNER_V1
    # Queued-chat browser API belongs to the laptop controller, not the public
    # controller and not CT101's frontend. This does not enable queued chat; the
    # controller flags still decide whether the route is active.
    if path == "/api/chat/queued" or path.startswith("/api/chat/queued/"):
        return CONTROLLER, path

    # FAST_BACKEND_PROXY_V2
    # Send CT101 app API calls directly to FastAPI, not through Next.
    if path.startswith("/api/backend/"):
        return CT101_API, "/api/" + path.split("/api/backend/", 1)[1]
    controller_exact = {
        "/api/me": "/system/session/me",
        "/api/session/presence": "/system/session/presence",
        "/api/presence/web": "/system/presence/web",
        "/api/presence/power-policy": "/system/presence/power-policy",
        "/api/presence/apply-power-policy": "/system/presence/apply-power-policy",
        "/api/auth/login": "/system/session/login",
        "/api/auth/me": "/system/session/me",
        "/api/auth/register": "/system/session/register",
        "/api/auth/logout": "/system/session/logout-safe",
        "/api/account/credits": "/system/account/credits",
        "/api/account/credit-pools": "/system/account/credit-pools",
        "/api/ads/reward/status": "/system/ads/reward/status",
        "/api/ads/reward/claim": "/system/ads/reward/claim",
        "/api/gpu/catalog": "/system/gpu/catalog",
        "/api/gpu/quote": "/system/gpu/quote",
        "/api/gpu/reserve-quote": "/system/gpu/reserve-quote",
        "/api/gpu/sessions": "/system/gpu/sessions",
        "/api/gpu/start-reserved": "/system/gpu/start-reserved",
        "/api/gpu/stop-session": "/system/gpu/stop-session",
        "/api/gpu/cleanup-mock-session": "/system/gpu/cleanup-mock-session",
        "/api/credits/reserve-v2": "/system/credits/reserve-v2",
        "/api/credits/commit-v2": "/system/credits/commit-v2",
        "/api/credits/refund-v2": "/system/credits/refund-v2",
        "/api/credits/grant-free": "/system/credits/grant-free",
        "/api/credits/grant-paid": "/system/credits/grant-paid",
        "/api/credits/reserve": "/system/credits/reserve",
        "/api/credits/commit": "/system/credits/commit",
        "/api/credits/refund": "/system/credits/refund",
        "/api/credits/grant": "/system/credits/grant",
        "/api/admin/users": "/system/admin/users",
        "/api/admin/support/tickets": "/system/admin/support/tickets",
        "/api/support/tickets": "/system/support/tickets",
    }

    if path in controller_exact:
        return CONTROLLER, controller_exact[path]

    if path.startswith("/api/support/tickets/"):
        return CONTROLLER, path.replace("/api/support/", "/system/support/", 1)

    if path.startswith("/api/system/"):
        return CONTROLLER, path.replace("/api/system/", "/system/", 1)

    if path == "/api/auth/me":
        return CONTROLLER, "/system/session/me"

    if path.startswith("/api/study/"):
        return CONTROLLER, path

    if path.startswith("/api/companion/"):
        return CONTROLLER, path

    if path.startswith("/api/calendar/"):
        return CONTROLLER, path

    return CONTROLLER, path


class SPAProxyHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # NEXT_STATIC_CACHE_V1
        # Private HTML/API stays no-store, but Next static chunks should cache.
        try:
            path = urlparse(self.path).path or "/"
        except Exception:
            path = ""

        if path.startswith("/_next/static/"):
            self.send_header("Cache-Control", "public, max-age=31536000, immutable")
        elif path.startswith("/_next/image"):
            self.send_header("Cache-Control", "public, max-age=3600")
        else:
            self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
            self.send_header("Pragma", "no-cache")
            self.send_header("Expires", "0")

        return super().end_headers()

    def _auth_route_token(self):
        raw_cookie = self.headers.get("Cookie", "")
        try:
            cookie = SimpleCookie()
            cookie.load(raw_cookie)
            value = cookie.get("edgeStudyToken")
            return value.value if value and value.value else ""
        except Exception:
            marker = "edgeStudyToken="
            if marker not in raw_cookie:
                return ""
            return raw_cookie.split(marker, 1)[1].split(";", 1)[0].strip()

    def _has_auth_route_cookie(self):
        return bool(self._auth_route_token())


    def _serve_absolute_file(self, file_path):
        file_path = Path(file_path)
        if not file_path.exists() or not file_path.is_file():
            self.send_error(404)
            return
        ctype = mimetypes.guess_type(str(file_path))[0] or "application/octet-stream"
        data = file_path.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        self.end_headers()
        self.wfile.write(data)

    def _should_proxy_full_app(self, path):
        # The laptop wrapper is now the page owner.
        # Do not proxy logged-in page documents like /study to old CT101 :3010.
        return False


    # EDGE_USER_HEADER_BRIDGE_V1
    def _controller_user_from_token(self):
        token = self._auth_route_token()
        if not token:
            auth = self.headers.get("Authorization", "")
            if auth.lower().startswith("bearer "):
                token = auth.split(" ", 1)[1].strip()

        if not token:
            return None

        # STAGE_5H3_WRAPPER_SESSION_COOKIE_USER_LOOKUP_V1
        # Internal wrapper lookup should support both auth forms because the
        # browser session is same-domain cookie based. This does not expose the
        # token to the browser; it only helps the wrapper derive trusted headers.
        lookup_headers = {
            "Authorization": f"Bearer {token}",
            "Cookie": f"edgeStudyToken={token}",
            "Accept": "application/json",
        }

        req = urllib.request.Request(
            CONTROLLER + "/system/session/me",
            headers=lookup_headers,
            method="GET",
        )

        try:
            with urllib.request.urlopen(req, timeout=5) as resp:
                data = json.loads(resp.read().decode() or "{}")
                return data.get("user") or data
        except Exception:
            return self._stage5h3_user_from_local_session_token(token)

    # STAGE_5H3_WRAPPER_LOCAL_SESSION_RESOLVER_FALLBACK_V1
    # The wrapper may need to derive trusted CT101 headers for local smoke-created
    # sessions that are valid in app_sessions but not accepted by /system/session/me.
    # This remains server-side: it derives user identity from the session token hash
    # and never accepts user_id from the browser payload.
    def _stage5h3_user_from_local_session_token(self, token):
        clean_token = str(token or "").strip()
        if not clean_token:
            return None

        try:
            from edge_modules.chat_queue_session_auth import hash_session_token
            from edge_modules.chat_queue_persistence import _psql_at, _sql_literal

            token_hash = hash_session_token(clean_token)
            raw = _psql_at(
                f"""
                SELECT COALESCE(
                  (
                    SELECT row_to_json(u)::text
                    FROM (
                      SELECT
                        u.id,
                        u.email,
                        COALESCE(u.display_name, '') AS display_name,
                        COALESCE(u.is_admin, FALSE) AS is_admin
                      FROM app_sessions s
                      JOIN app_users u
                        ON u.id = s.user_id
                      WHERE s.token_hash = {_sql_literal(token_hash)}
                        AND s.revoked_at IS NULL
                        AND s.expires_at > now()
                        AND u.is_active = TRUE
                      LIMIT 1
                    ) u
                  ),
                  ''
                );
                """
            )

            if not raw:
                return None

            return json.loads(raw)
        except Exception:
            return None

    # STAGE_5H3_WRAPPER_NORMALIZE_CT101_EDGE_USER_ID_V1
    # If the local session now resolves to the mirrored laptop user id
    # "ct101:<source>", send only "<source>" as X-Edge-User-Id because the
    # controller itself owns the ct101 namespace prefixing.
    def _stage5h3_edge_user_id_for_trusted_header(self, user):
        raw = str((user or {}).get("id") or "").strip()
        if raw.startswith("ct101:"):
            return raw.split(":", 1)[1]
        return raw

    def _inject_trusted_edge_headers(self, headers, upstream_path, original_path=None):
        auth_bridge_path = original_path or upstream_path
        if not auth_bridge_path.startswith("/api/backend/"):
            return

        if not EDGE_TRUSTED_PROXY_SECRET:
            return

        user = self._controller_user_from_token()
        if not user:
            return

        headers["X-Edge-Auth-Secret"] = EDGE_TRUSTED_PROXY_SECRET
        headers["X-Edge-User-Id"] = self._stage5h3_edge_user_id_for_trusted_header(user)
        headers["X-Edge-User-Email"] = str(user.get("email") or "")
        headers["X-Edge-User-Is-Admin"] = "true" if user.get("is_admin") else "false"


    def _proxy_to_backend(self, backend, upstream_path, query="", original_path=None):
        upstream_url = backend + upstream_path
        if query:
            upstream_url += "?" + query

        body = None
        if self.command in ("POST", "PUT", "PATCH"):
            length = int(self.headers.get("Content-Length", "0") or "0")
            body = self.rfile.read(length) if length else None

        headers = {"User-Agent": "wrapper-proxy/3.0"}

        for name in (
            "Authorization",
            "Content-Type",
            "Cookie",
            "Accept",
            "RSC",
            "Next-Router-State-Tree",
            "Next-Router-Prefetch",
            "Next-Router-Segment-Prefetch",
            "X-Queued-Chat-Session-Token",
        ):
            value = self.headers.get(name)
            if value:
                headers[name] = value

        # BACKEND_COOKIE_TO_BEARER_ORIGINAL_PATH_V1
        # Browser has edgeStudyToken as a cookie for same-domain routing.
        # CT101 backend requests arrive at the wrapper as /api/backend/*, then
        # map_api() rewrites them to CT101's real /api/* path. Use the original
        # browser path so cookie-to-bearer auth still happens after mapping.
        auth_source_path = original_path or upstream_path

        # STAGE_5G7_QUEUED_CHAT_COOKIE_TO_SESSION_HEADER_V1
        # The browser queued-chat helper uses credentials: include and must not
        # read or send raw identity fields. Bridge the existing same-domain
        # edgeStudyToken cookie to the controller-only queued-chat session header
        # inside the wrapper for laptop-owned queued-chat routes.
        if (
            auth_source_path == "/api/chat/queued"
            or auth_source_path.startswith("/api/chat/queued/")
        ) and not headers.get("X-Queued-Chat-Session-Token"):
            token = self._auth_route_token()
            if token:
                headers["X-Queued-Chat-Session-Token"] = token
        if (
            auth_source_path.startswith("/api/backend/")
            or auth_source_path.startswith("/api/study/")
            or auth_source_path.startswith("/api/companion/")
            or auth_source_path == "/api/auth/me"
            or auth_source_path == "/api/me"
        ) and not headers.get("Authorization"):
            token = self._auth_route_token()
            if token:
                headers["Authorization"] = f"Bearer {token}"

        if (
            auth_source_path.startswith("/api/study/")
            or auth_source_path.startswith("/api/companion/")
            or auth_source_path.startswith("/api/calendar/")
        ) and EDGE_PUBLIC_API_KEY and not headers.get("x-edge-api-key"):
            headers["x-edge-api-key"] = EDGE_PUBLIC_API_KEY

        self._inject_trusted_edge_headers(headers, upstream_path, original_path=original_path)

        req = urllib.request.Request(
            upstream_url,
            data=body,
            headers=headers,
            method=self.command,
        )

        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = resp.read()

                self.send_response(resp.status)

                for header in (
                    "Content-Type",
                    "Location",
                    "Vary",
                    "Set-Cookie",
                ):
                    for value in resp.headers.get_all(header, []):
                        self.send_header(header, value)

                self.end_headers()

                if self.command != "HEAD":
                    self.wfile.write(data)

        except urllib.error.HTTPError as e:
            data = e.read()
            self.send_response(e.code)

            for header in ("Content-Type", "Location", "Vary", "Set-Cookie"):
                for value in e.headers.get_all(header, []):
                    self.send_header(header, value)

            self.end_headers()

            if self.command != "HEAD":
                self.wfile.write(data)

        except BrokenPipeError:
            pass

        except Exception as e:
            data = (
                '{"ok":false,"detail":"Proxy failed: %s"}'
                % str(e).replace('"', '\\"')
            ).encode()

            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.end_headers()

            if self.command != "HEAD":
                self.wfile.write(data)


    # STAGE_5G9_CT101_QUEUED_CHAT_BRIDGE_V1
    # Optional compatibility bridge for the currently active CT101 ChatPage.
    # CT101 ChatPage calls:
    #   POST /api/backend/chats/{chat_id}/messages/queued
    #   GET  /api/backend/chats/{chat_id}/messages/jobs/{job_id}
    #
    # Laptop controller owns:
    #   POST /api/chat/queued
    #   GET  /api/chat/queued/{job_id}
    #
    # This bridge is disabled unless WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED=1.
    def _send_stage5g9_json(self, status, payload):
        data = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()

        if self.command != "HEAD":
            self.wfile.write(data)

    def _stage5g9_read_json_body(self):
        length = int(self.headers.get("Content-Length", "0") or "0")
        raw = self.rfile.read(length) if length else b""

        if not raw:
            return {}

        try:
            return json.loads(raw.decode() or "{}")
        except Exception as exc:
            raise ValueError(f"invalid JSON body: {exc}") from exc

    def _stage5g9_controller_headers(self):
        headers = {
            "User-Agent": "wrapper-proxy/3.0-stage5g9",
            "Accept": "application/json",
            "Content-Type": "application/json",
        }

        auth = self.headers.get("Authorization")
        if auth:
            headers["Authorization"] = auth

        token = self.headers.get("X-Queued-Chat-Session-Token") or self._auth_route_token()
        if token:
            headers["X-Queued-Chat-Session-Token"] = token

        # STAGE_5G14_FORWARD_TRUSTED_CT101_IDENTITY_TO_CONTROLLER_V1
        # The controller validates EDGE_TRUSTED_PROXY_SECRET before using
        # these X-Edge-* headers. This lets the laptop queue trust the wrapper,
        # not the browser, for CT101-authenticated chat requests.
        self._inject_trusted_edge_headers(
            headers,
            "/api/chat/queued",
            original_path="/api/backend/chats/_/messages/queued",
        )

        return headers

    def _stage5g9_controller_json(self, upstream_path, method, payload=None):
        body = None
        if payload is not None:
            body = json.dumps(payload).encode()

        req = urllib.request.Request(
            CONTROLLER + upstream_path,
            data=body,
            headers=self._stage5g9_controller_headers(),
            method=method,
        )
        # STAGE_5H3_WRAPPER_CONTROLLER_JSON_TRUSTED_HEADER_INJECTION_V1
        # Ensure queued create/status bridge calls to the laptop controller carry
        # the same server-derived trusted CT101 identity headers.
        try:
            trusted_headers = self._inject_trusted_edge_headers({}, upstream_path, getattr(self, "path", None))
            for _stage5h3_key, _stage5h3_value in (trusted_headers or {}).items():
                if _stage5h3_value is not None:
                    req.add_header(str(_stage5h3_key), str(_stage5h3_value))
        except Exception:
            pass

        # STAGE_5H3_WRAPPER_CONTROLLER_JSON_DIRECT_TRUSTED_HEADERS_V1
        # Direct fallback for laptop queued create/status controller calls. This
        # derives identity only from the server-side session resolver and never
        # accepts client-provided user_id.
        try:
            if str(upstream_path or "").startswith("/api/chat/queued") and EDGE_TRUSTED_PROXY_SECRET:
                stage5h3_user = self._controller_user_from_token()
                if stage5h3_user and stage5h3_user.get("id"):
                    req.add_header("X-Edge-Auth-Secret", EDGE_TRUSTED_PROXY_SECRET)
                    req.add_header("X-Edge-User-Id", self._stage5h3_edge_user_id_for_trusted_header(stage5h3_user))
                    req.add_header("X-Edge-User-Email", str(stage5h3_user.get("email") or ""))
                    req.add_header("X-Edge-User-Is-Admin", "true" if stage5h3_user.get("is_admin") else "false")
        except Exception:
            pass

        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                raw = resp.read()
                status = resp.status
        except urllib.error.HTTPError as exc:
            raw = exc.read()
            status = exc.code

        try:
            data = json.loads(raw.decode() or "{}")
        except Exception:
            data = {"raw": raw.decode(errors="replace")}

        return status, data

    def _stage5g9_transform_create_response(self, chat_id, data):
        if not isinstance(data, dict):
            return data

        out = dict(data)
        out.setdefault("mode", "queued")
        out.setdefault("chat_id", chat_id)

        if "status" not in out and isinstance(out.get("job"), dict):
            out["status"] = out["job"].get("status")

        return out

    def _stage5g9_transform_status_response(self, chat_id, job_id, data):
        if not isinstance(data, dict):
            return data

        out = dict(data)
        job = out.get("job") if isinstance(out.get("job"), dict) else {}

        out.setdefault("mode", "queued")
        out.setdefault("chat_id", chat_id)
        out.setdefault("job_id", job_id)
        out.setdefault("status", job.get("status") or out.get("status"))

        # STAGE_5G10_CT101_COMPAT_ASSISTANT_MESSAGE_V1
        # CT101 ChatPage waits for:
        #   pollData.status === "complete" && pollData.assistant_message
        #
        # The laptop controller status route returns the completed job and
        # result_json. Convert that to CT101-compatible assistant_message only
        # for complete jobs with a non-empty reply. This does not write an
        # assistant message row and therefore cannot duplicate final messages.
        assistant_message = out.get("assistant_message")

        if assistant_message is None and out.get("status") == "complete":
            result = job.get("result_json") or out.get("result_json") or {}

            if isinstance(result, str):
                try:
                    result = json.loads(result or "{}")
                except Exception:
                    result = {}

            reply = ""
            if isinstance(result, dict):
                reply = str(
                    result.get("reply")
                    or result.get("response")
                    or result.get("content")
                    or ""
                ).strip()

            if reply:
                assistant_id = ""
                if isinstance(result, dict):
                    assistant_id = str(
                        result.get("chat_assistant_message_id")
                        or result.get("assistant_message_id")
                        or ""
                    ).strip()

                if not assistant_id:
                    assistant_id = f"{job_id}-assistant"

                assistant_message = {
                    "id": assistant_id,
                    "role": "assistant",
                    "content": reply,
                    "risk_level": 0,
                    "created_at": (
                        job.get("finished_at")
                        or job.get("updated_at")
                        or job.get("created_at")
                    ),
                }

        out["assistant_message"] = assistant_message

        return out

    def _try_stage5g9_ct101_queued_chat_bridge(self, path):
        if not WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED:
            return False

        create_match = re.fullmatch(r"/api/backend/chats/([^/]+)/messages/queued", path)
        if create_match:
            if self.command != "POST":
                self._send_stage5g9_json(405, {"ok": False, "error": "method_not_allowed_stage_5g9"})
                return True

            chat_id = create_match.group(1)

            try:
                ct101_payload = self._stage5g9_read_json_body()
            except ValueError as exc:
                self._send_stage5g9_json(400, {"ok": False, "error": "invalid_json_stage_5g9", "message": str(exc)})
                return True

            laptop_payload = {
                "message": str(ct101_payload.get("content") or ""),
                "chat_id": chat_id,
            }

            if ct101_payload.get("model"):
                laptop_payload["requested_model"] = str(ct101_payload.get("model"))

            # STAGE_5H2_COMPANION_MODE_OWNERSHIP_V1
            # Forward only allowed non-identity chat modes. The controller still
            # derives user ownership from session/trusted wrapper identity.
            declared_mode = str(
                ct101_payload.get("mode")
                or ct101_payload.get("chat_mode")
                or ""
            ).strip().lower()
            if declared_mode in {"chat", "companion"}:
                laptop_payload["mode"] = declared_mode

            status, data = self._stage5g9_controller_json(
                "/api/chat/queued",
                "POST",
                laptop_payload,
            )

            self._send_stage5g9_json(
                status,
                self._stage5g9_transform_create_response(chat_id, data),
            )
            return True

        status_match = re.fullmatch(r"/api/backend/chats/([^/]+)/messages/jobs/([^/]+)", path)
        if status_match:
            if self.command != "GET":
                self._send_stage5g9_json(405, {"ok": False, "error": "method_not_allowed_stage_5g9"})
                return True

            chat_id = status_match.group(1)
            job_id = status_match.group(2)

            status, data = self._stage5g9_controller_json(
                f"/api/chat/queued/{job_id}",
                "GET",
                None,
            )

            self._send_stage5g9_json(
                status,
                self._stage5g9_transform_status_response(chat_id, job_id, data),
            )
            return True

        return False


    def _proxy_api(self):
        parsed = urlparse(self.path)

        if self._try_stage5g9_ct101_queued_chat_bridge(parsed.path):
            return

        backend, upstream_path = map_api(parsed.path)
        return self._proxy_to_backend(backend, upstream_path, parsed.query, original_path=parsed.path)

    def _serve_wrapper_or_static(self):
        parsed = urlparse(self.path)
        path = parsed.path or "/"

        local_path = Path("." + path)

        if path == "/study" or path.startswith("/study/"):
            rel = path.removeprefix("/study").lstrip("/")
            if not rel:
                rel = "index.html"
            study_path = REPO_ROOT / "frontend" / "study-ui" / rel
            if study_path.exists() and study_path.is_file():
                return self._serve_absolute_file(study_path)
            return self._serve_absolute_file(REPO_ROOT / "frontend" / "study-ui" / "index.html")

        if local_path.exists() and local_path.is_file():
            return super().do_GET()

        if path in WRAPPER_ROUTES or "." not in Path(path).name:
            self.path = "/index.html"
            return super().do_GET()

        return super().do_GET()

    def do_HEAD(self):
        parsed = urlparse(self.path)
        path = parsed.path or "/"

        if path.startswith("/api/"):
            return self._proxy_api()

        if self._should_proxy_full_app(path):
            return self._proxy_to_backend(CT101_FRONTEND, path, parsed.query)

        original = self.command
        self.command = "HEAD"
        try:
            return self._serve_wrapper_or_static()
        finally:
            self.command = original

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path or "/"

        if path.startswith("/api/"):
            return self._proxy_api()

        if self._should_proxy_full_app(path):
            return self._proxy_to_backend(CT101_FRONTEND, path, parsed.query)

        return self._serve_wrapper_or_static()

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path or "/"

        if path.startswith("/api/"):
            return self._proxy_api()

        self.send_error(404)

    def do_PUT(self):
        return self.do_POST()

    def do_PATCH(self):
        return self.do_POST()

    def do_DELETE(self):
        parsed = urlparse(self.path)
        path = parsed.path or "/"

        if path.startswith("/api/"):
            return self._proxy_api()

        self.send_error(404)


if __name__ == "__main__":
    os.chdir(Path(__file__).resolve().parent)
    print(f"Serving wrapper UI at http://127.0.0.1:{PORT}")
    ThreadingHTTPServer(("127.0.0.1", PORT), SPAProxyHandler).serve_forever()
