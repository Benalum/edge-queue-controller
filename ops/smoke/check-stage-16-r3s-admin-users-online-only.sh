#!/usr/bin/env bash
set -euo pipefail

fail=0

require_file_contains() {
  local file="$1"
  local needle="$2"
  if ! grep -Fq "$needle" "$file"; then
    echo "MISSING: $file :: $needle" >&2
    fail=1
  fi
}

require_file_contains frontend/wrapper-ui/app.js "APC_ADMIN_USERS_ONLY_PAGE_R3S"
require_file_contains frontend/wrapper-ui/app.js "Admin users"
require_file_contains frontend/wrapper-ui/app.js "Refresh users"
require_file_contains frontend/wrapper-ui/app.js "online"
require_file_contains frontend/wrapper-ui/app.js "offline"
require_file_contains frontend/wrapper-ui/app.js "All non-deleted platform users"
require_file_contains frontend/wrapper-ui/app.js 'const ADMIN_PATHS = ["/api/admin/users", "/system/admin/users"]'

require_file_contains edge_controller.py '@app.get("/api/admin/users")'
require_file_contains edge_controller.py '@app.get("/admin/users")'
require_file_contains edge_controller.py '@app.get("/system/admin/users")'
require_file_contains edge_controller.py 'ADMIN_ONLINE_WINDOW_SECONDS'
require_file_contains edge_controller.py '"online": is_online'

require_file_contains public_gateway.py 'async def _admin_users_api_proxy_r3s'
require_file_contains public_gateway.py '"/api/admin/users", "/api/system/admin/users"'
require_file_contains public_gateway.py '"/system/admin/users"'

require_file_contains cloudflare/edge-public-proxy/src/index.js '/^\/api\/admin\/users$/'
require_file_contains cloudflare/edge-public-proxy/src/index.js 'if (path === "/api/admin/users") return "/system/admin/users";'
require_file_contains frontend/wrapper-ui/dev_server.py 'auth_source_path.startswith("/api/admin/")'

python3 - <<'PY'
from pathlib import Path
src = Path('frontend/wrapper-ui/app.js').read_text()
start = src.index('/* APC_ADMIN_USERS_ONLY_PAGE_R3S_BEGIN */')
end = src.index('/* APC_ADMIN_USERS_ONLY_PAGE_R3S_END */')
block = src[start:end]
for forbidden in ['Support Inbox', 'Admin credit tools', 'Infrastructure', 'Open System', 'Platform controls', 'User support']:
    assert forbidden not in block, forbidden
assert 'renderPage = function' in block
assert 'fetchAdminUsersOnly' in block
assert 'renderRows(users)' in block

backend = Path('edge_controller.py').read_text()
fn_start = backend.index('@app.get("/api/admin/users")')
fn_end = backend.index('@app.post("/system/support/tickets")')
fn = backend[fn_start:fn_end]
assert 'LIMIT 250' not in fn
assert '_admin_support_require_admin(request)' in fn
assert 'WHERE COALESCE(u.status' in fn
print('PASS: R3S admin users-only source contract')
PY

node --check frontend/wrapper-ui/app.js >/dev/null
node --check cloudflare/edge-public-proxy/src/index.js >/dev/null
python3 -m py_compile edge_controller.py public_gateway.py frontend/wrapper-ui/dev_server.py

if [[ "$fail" -ne 0 ]]; then
  exit "$fail"
fi

echo "PASS: stage-16-r3s-admin-users-online-only"
