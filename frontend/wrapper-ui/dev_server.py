from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse
import urllib.request
import urllib.error

CONTROLLER = "http://127.0.0.1:7070"
GATEWAY = "http://127.0.0.1:7071"
PORT = 8787


def map_api(path):
    if path == "/api/me":
        return CONTROLLER, "/system/session/me"

    if path == "/api/auth/login":
        return CONTROLLER, "/system/session/login"

    if path == "/api/auth/register":
        return CONTROLLER, "/system/session/register"

    if path == "/api/auth/logout":
        return CONTROLLER, "/system/session/logout"

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

    if path.startswith("/api/system/"):
        return GATEWAY, path.replace("/api/system/", "/system/", 1)

    if path.startswith("/api/study/"):
        return GATEWAY, path.replace("/api/study/", "/public/study/", 1)

    if path.startswith("/api/companion/"):
        return GATEWAY, path.replace("/api/companion/", "/public/companion/", 1)

    return GATEWAY, path.replace("/api", "", 1) or "/"


class SPAProxyHandler(SimpleHTTPRequestHandler):
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

        for name in ("Authorization", "Content-Type"):
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
                self.end_headers()
                self.wfile.write(data)

        except urllib.error.HTTPError as e:
            data = e.read()
            self.send_response(e.code)
            self.send_header("Content-Type", e.headers.get("Content-Type", "application/json"))
            self.send_header("Cache-Control", "no-store")
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
    print(f"Serving wrapper UI at http://127.0.0.1:{PORT}")
    print("Auth/me routes      -> controller 7070 /system/session/*")
    print("Credits routes      -> controller 7070 /system/credits/*")
    print("System routes       -> gateway 7071 /system/*")
    print("Study/companion API -> gateway 7071 /public/*")
    ThreadingHTTPServer(("127.0.0.1", PORT), SPAProxyHandler).serve_forever()
