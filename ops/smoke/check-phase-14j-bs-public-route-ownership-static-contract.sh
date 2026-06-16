#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BS reusable smoke: public route ownership static contract ==="
echo "MUTATION_SCOPE=read_only_static_contract"
echo "NO CT101 call"
echo "NO model/Ollama endpoint call"
echo "NO DB mutation"
echo "NO job mutation"
echo "NO runtime activation"

test -f edge_controller.py
python3 -m py_compile edge_controller.py
echo "PASS: edge_controller.py compiles"

route_hits="$(grep -RIn --exclude-dir=.git --exclude-dir=.cgpt-bridge --exclude-dir=cleanup --exclude-dir=.cleanup-archive --exclude-dir=.cleanup-backups --exclude='*.sqlite3' --exclude='*.db' -E 'route|Route|@app|FastAPI|/api/|/study|/companion|/calendar|/profile|/account|/credits|/system|/admin' . 2>/dev/null | wc -l | tr -d ' ')"
controller_api_hits="$(grep -RIn --exclude-dir=.git --exclude-dir=.cgpt-bridge --exclude-dir=cleanup --exclude-dir=.cleanup-archive --exclude-dir=.cleanup-backups --exclude='*.sqlite3' --exclude='*.db' -E '/api/auth|/api/account|/api/credits|/api/system|/api/jobs|/profile|/login|/register' . 2>/dev/null | wc -l | tr -d ' ')"
ct101_proxy_hits="$(grep -RIn --exclude-dir=.git --exclude-dir=.cgpt-bridge --exclude-dir=cleanup --exclude-dir=.cleanup-archive --exclude-dir=.cleanup-backups --exclude='*.sqlite3' --exclude='*.db' -E '/api/study|/api/companion|/api/calendar|study-app|companion-app|calendar-app' . 2>/dev/null | wc -l | tr -d ' ')"
public_gateway_hits="$(grep -RIn --exclude-dir=.git --exclude-dir=.cgpt-bridge --exclude-dir=cleanup --exclude-dir=.cleanup-archive --exclude-dir=.cleanup-backups --exclude='*.sqlite3' --exclude='*.db' -E 'public gateway|Public gateway|gateway|Gateway|proxy|Proxy|route ownership|Route ownership' docs edge_controller.py ops 2>/dev/null | wc -l | tr -d ' ')"

printf 'route_hits=%s\n' "$route_hits"
printf 'controller_api_hits=%s\n' "$controller_api_hits"
printf 'ct101_proxy_hits=%s\n' "$ct101_proxy_hits"
printf 'public_gateway_hits=%s\n' "$public_gateway_hits"

if [ "$route_hits" -le 0 ]; then
  echo "FAIL: no route/static ownership markers found"
  exit 1
fi

echo
echo "=== top route ownership files ==="
grep -RIl \
  --exclude-dir=.git \
    --exclude-dir=.cgpt-bridge \
    --exclude-dir=cleanup \
    --exclude-dir=.cleanup-archive \
    --exclude-dir=.cleanup-backups \
  --exclude-dir=__pycache__ \
  --exclude-dir=node_modules \
  --exclude-dir=.venv \
  --exclude-dir=venv \
  --exclude='*.sqlite3' \
  --exclude='*.db' \
  --include='*.py' \
  --include='*.js' \
  --include='*.ts' \
  --include='*.tsx' \
  --include='*.html' \
  --include='*.md' \
  --include='*.sh' \
  -E 'route|Route|@app|FastAPI|/api/|/study|/companion|/calendar|/profile|/account|/credits|/system|/admin' . 2>/dev/null \
  | sed 's#^\./##' \
  | sort \
  | head -60 || true

echo
echo "PASS: public route ownership static contract completed"
