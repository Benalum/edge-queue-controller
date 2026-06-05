from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse
from http.cookies import SimpleCookie
import os
import urllib.error
import urllib.request


CONTROLLER = os.getenv("EDGE_CONTROLLER_URL", "http://127.0.0.1:7070")
GATEWAY = os.getenv("EDGE_PUBLIC_GATEWAY_URL", "http://127.0.0.1:7071")
CT101_FRONTEND = os.getenv("CT101_FRONTEND", "http://100.88.245.33:3010")
PORT = int(os.getenv("WRAPPER_UI_PORT", "8787"))

FULL_APP_ROUTES = {"/study", "/companion", "/calendar", "/profile"}
WRAPPER_ROUTES = {"/", "/study", "/companion", "/calendar", "/profile", "/system"}


def map_api(path):
    if path.startswith("/api/backend/"):
        return CT101_FRONTEND, path

    # CT101_AUTH_SOURCE_OF_TRUTH_V1
    # CT 101 owns real app auth/user/credits. The laptop wrapper stays as
    # public shell + system/wake/status proxy.
    ct101_auth_exact = {
        "/api/me": "/api/backend/auth/me",
        "/api/auth/login": "/api/backend/auth/login",
        "/api/auth/register": "/api/backend/auth/register",
        "/api/auth/logout": "/api/backend/auth/logout",
        "/api/account/credits": "/api/backend/account/credits",
        "/api/account/credit-pools": "/api/backend/account/credits",
    }

    if path in ct101_auth_exact:
        return CT101_FRONTEND, ct101_auth_exact[path]

    controller_exact = {
        "/api/me": "/system/session/me",
        "/api/session/presence": "/system/session/presence",
        "/api/presence/web": "/system/presence/web",
        "/api/presence/power-policy": "/system/presence/power-policy",
        "/api/presence/apply-power-policy": "/system/presence/apply-power-policy",
        "/api/auth/login": "/system/session/login",
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
        return GATEWAY, path.replace("/api/system/", "/system/", 1)

    if path.startswith("/api/study/"):
        return GATEWAY, path.replace("/api/study/", "/public/study/", 1)

    if path.startswith("/api/companion/"):
        return GATEWAY, path.replace("/api/companion/", "/public/companion/", 1)

    return GATEWAY, path.replace("/api", "", 1) or "/"


class SPAProxyHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
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

    def _should_proxy_full_app(self, path):
        if not self._has_auth_route_cookie():
            return False

        return (
            path in FULL_APP_ROUTES
            or path.startswith("/_next/")
            or path.startswith("/api/backend/")
        )

    def _proxy_to_backend(self, backend, upstream_path, query=""):
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
        ):
            value = self.headers.get(name)
            if value:
                headers[name] = value

        # BACKEND_COOKIE_TO_BEARER_V1
        # Browser has edgeStudyToken as a cookie for same-domain routing.
        # CT101 /api/backend routes need Authorization so FastAPI can authenticate.
        if upstream_path.startswith("/api/backend/") and not headers.get("Authorization"):
            token = self._auth_route_token()
            if token:
                headers["Authorization"] = f"Bearer {token}"

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

    def _proxy_api(self):
        parsed = urlparse(self.path)
        backend, upstream_path = map_api(parsed.path)
        return self._proxy_to_backend(backend, upstream_path, parsed.query)

    def _serve_wrapper_or_static(self):
        parsed = urlparse(self.path)
        path = parsed.path or "/"

        local_path = Path("." + path)

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
