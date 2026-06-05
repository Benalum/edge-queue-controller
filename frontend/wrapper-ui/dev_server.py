from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import os
from urllib.parse import urlparse
import urllib.request
import urllib.error

CONTROLLER = "http://127.0.0.1:7070"
GATEWAY = "http://127.0.0.1:7071"
PORT = 8787


def map_api(path):
    if path == "/api/me":
        return CONTROLLER, "/system/session/me"

    if path == "/api/session/presence":
        return CONTROLLER, "/system/session/presence"

    if path == "/api/presence/web":
        return CONTROLLER, "/system/presence/web"

    if path == "/api/presence/power-policy":
        return CONTROLLER, "/system/presence/power-policy"

    if path == "/api/presence/apply-power-policy":
        return CONTROLLER, "/system/presence/apply-power-policy"


    if path == "/api/auth/login":
        return CONTROLLER, "/system/session/login"

    if path == "/api/auth/register":
        return CONTROLLER, "/system/session/register"

    if path == "/api/auth/logout":
        return CONTROLLER, "/system/session/logout-safe"

    if path == "/api/account/credits":
        return CONTROLLER, "/system/account/credits"

    if path == "/api/ads/reward/status":
        return CONTROLLER, "/system/ads/reward/status"

    if path == "/api/ads/reward/claim":
        return CONTROLLER, "/system/ads/reward/claim"

    if path == "/api/account/credit-pools":
        return CONTROLLER, "/system/account/credit-pools"

    if path == "/api/gpu/catalog":
        return CONTROLLER, "/system/gpu/catalog"

    if path == "/api/gpu/quote":
        return CONTROLLER, "/system/gpu/quote"

    if path == "/api/gpu/reserve-quote":
        return CONTROLLER, "/system/gpu/reserve-quote"

    if path == "/api/gpu/sessions":
        return CONTROLLER, "/system/gpu/sessions"

    if path == "/api/gpu/start-reserved":
        return CONTROLLER, "/system/gpu/start-reserved"

    if path == "/api/gpu/stop-session":
        return CONTROLLER, "/system/gpu/stop-session"

    if path == "/api/gpu/cleanup-mock-session":
        return CONTROLLER, "/system/gpu/cleanup-mock-session"


    if path == "/api/credits/reserve-v2":
        return CONTROLLER, "/system/credits/reserve-v2"

    if path == "/api/credits/commit-v2":
        return CONTROLLER, "/system/credits/commit-v2"

    if path == "/api/credits/refund-v2":
        return CONTROLLER, "/system/credits/refund-v2"

    if path == "/api/credits/grant-free":
        return CONTROLLER, "/system/credits/grant-free"

    if path == "/api/credits/grant-paid":
        return CONTROLLER, "/system/credits/grant-paid"


    if path == "/api/credits/reserve":
        return CONTROLLER, "/system/credits/reserve"

    if path == "/api/credits/commit":
        return CONTROLLER, "/system/credits/commit"

    if path == "/api/credits/refund":
        return CONTROLLER, "/system/credits/refund"

    if path == "/api/credits/grant":
        return CONTROLLER, "/system/credits/grant"

    if path == "/api/admin/users":
        return CONTROLLER, "/system/admin/users"

    if path == "/api/admin/support/tickets":
        return CONTROLLER, "/system/admin/support/tickets"

    if path == "/api/support/tickets":
        return CONTROLLER, "/system/support/tickets"

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
    # FORCE_SPA_PUBLIC_ROUTES_V2
    def _maybe_rewrite_spa_route(self):
        from urllib.parse import urlparse

        parsed = urlparse(self.path)
        route_path = parsed.path or "/"

        # These are browser pages owned by the wrapper SPA.
        spa_routes = {
            "/",
            "/study",
            "/companion",
            "/calendar",
            "/profile",
            "/system",
        }

        if route_path in spa_routes:
            self.path = "/index.html"
            return True

        return False

    def do_HEAD(self):
        original_path = self.path
        self._maybe_rewrite_spa_route()
        try:
            return super().do_HEAD()
        finally:
            self.path = original_path

    def do_GET(self):
        original_path = self.path

        # Do not rewrite API/proxy routes.
        from urllib.parse import urlparse
        route_path = urlparse(self.path).path or "/"
        if (
            route_path.startswith("/api/")
            or route_path.startswith("/public/")
            or route_path.startswith("/system/")
        ):
            return super().do_GET()

        self._maybe_rewrite_spa_route()
        try:
            return super().do_GET()
        finally:
            self.path = original_path

    # SPA_FALLBACK_DEEP_ROUTES_V1
    def send_head(self):
        """
        Serve index.html for wrapper app routes like /study, /companion,
        /calendar, /profile, and /system so local dev matches Cloudflare Pages.
        API/proxy routes and real static files still use normal handling.
        """
        import os
        from urllib.parse import urlparse

        parsed = urlparse(self.path)
        route_path = parsed.path or "/"

        # API/proxy routes should not be rewritten to index.html.
        if (
            route_path.startswith("/api/")
            or route_path.startswith("/public/")
            or route_path.startswith("/system/")
        ):
            return super().send_head()

        translated = self.translate_path(route_path)

        # Existing files/directories should be served normally.
        if os.path.exists(translated):
            return super().send_head()

        # Browser SPA routes without file extensions should serve index.html.
        basename = os.path.basename(route_path)
        if "." not in basename:
            old_path = self.path
            self.path = "/index.html"
            try:
                return super().send_head()
            finally:
                self.path = old_path

        return super().send_head()

    def _proxy_api(self):
        parsed = urlparse(self.path)
        backend, upstream_path = map_api(parsed.path)
        upstream_url = backend + upstream_path

        if parsed.query:
            upstream_url += "?" + parsed.query

        body = None
        if self.command in ("POST", "PUT", "PATCH"):
            length = int(self.headers.get("Content-Length", "0") or "0")
            body = self.rfile.read(length) if length else None

        headers = {"User-Agent": "wrapper-local-dev-proxy/2.1"}

        for name in ("Authorization", "Content-Type", "Cookie", "Accept"):
            value = self.headers.get(name)
            if value:
                headers[name] = value

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
                self.send_header("Content-Type", resp.headers.get("Content-Type", "application/json"))
                self.send_header("Cache-Control", "no-store")

                for cookie in resp.headers.get_all("Set-Cookie", []):
                    self.send_header("Set-Cookie", cookie)

                self.end_headers()
                self.wfile.write(data)

        except urllib.error.HTTPError as e:
            data = e.read()
            self.send_response(e.code)
            self.send_header("Content-Type", e.headers.get("Content-Type", "application/json"))
            self.send_header("Cache-Control", "no-store")

            for cookie in e.headers.get_all("Set-Cookie", []):
                self.send_header("Set-Cookie", cookie)

            self.end_headers()
            self.wfile.write(data)

        except BrokenPipeError:
            pass

        except Exception as e:
            data = ('{"ok":false,"detail":"Local API proxy failed: %s"}' % str(e).replace('"', '\\"')).encode()
            try:
                self.send_response(502)
                self.send_header("Content-Type", "application/json")
                self.send_header("Cache-Control", "no-store")
                self.end_headers()
                self.wfile.write(data)
            except BrokenPipeError:
                pass

    def do_GET(self):
        requested = urlparse(self.path).path

        if requested.startswith("/api/"):
            return self._proxy_api()

        local_path = Path("." + requested)

        if local_path.exists() and local_path.is_file():
            return super().do_GET()

        if "." not in Path(requested).name:
            self.path = "/index.html"

        return super().do_GET()

    def do_POST(self):
        requested = urlparse(self.path).path

        if requested.startswith("/api/"):
            return self._proxy_api()

        self.send_error(404)


if __name__ == "__main__":
    # WRAPPER_UI_ROOT_CHDIR_V1
    # Serve static files from this script's folder, no matter what systemd's
    # WorkingDirectory is.
    os.chdir(Path(__file__).resolve().parent)

    print(f"Serving wrapper UI at http://127.0.0.1:{PORT}")
    print("Auth/me routes      -> controller 7070 /system/session/*")
    print("Credits routes      -> controller 7070 /system/credits/*")
    print("System routes       -> gateway 7071 /system/*")
    print("Study/companion API -> gateway 7071 /public/*")
    ThreadingHTTPServer(("127.0.0.1", PORT), SPAProxyHandler).serve_forever()
