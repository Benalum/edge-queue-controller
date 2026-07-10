#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-$(pwd)}"
cd "$ROOT"
APP="frontend/wrapper-ui/apc-wrapper-local"

printf '=== stage-17k-r16bu-local-first-study-companion-profile-support-source-only smoke ===\n'

for f in \
  "$APP/index.html" \
  "$APP/header/header.html" \
  "$APP/header/header.nav" \
  "$APP/publicpages/publicpages.js" \
  "$APP/privatepages/privatepages.js" \
  "$APP/privatepages/companion.js" \
  "$APP/privatepages/pages/profile.html" \
  "$APP/privatepages/pages/support.html" \
  "$APP/privatepages/profile-local-first-settings.js" \
  "$APP/privatepages/support.js"; do
  test -f "$f" || { echo "FAIL missing $f"; exit 1; }
done

node --check "$APP/publicpages/publicpages.js" >/dev/null
node --check "$APP/privatepages/privatepages.js" >/dev/null
node --check "$APP/privatepages/companion.js" >/dev/null
node --check "$APP/privatepages/profile-local-first-settings.js" >/dev/null
node --check "$APP/privatepages/support.js" >/dev/null

python3 - <<'PY'
from pathlib import Path
import json
app = Path('frontend/wrapper-ui/apc-wrapper-local')
nav = json.loads((app/'header/header.nav').read_text())
routes = [item.get('route') for item in nav.get('items', [])]
assert '/study' in routes, routes
assert '/companion' in routes, routes
assert '/profile' in routes, routes
assert '/support' in routes, routes
assert '/system' not in routes, routes
assert 'System' not in (app/'header/header.html').read_text()
publicpages = (app/'publicpages/publicpages.js').read_text()
assert 'file: "/publicpages/pages/study.html"' not in publicpages
assert 'file: "/publicpages/pages/companion.html"' not in publicpages
assert 'file: "/publicpages/pages/profile.html"' not in publicpages
assert 'file: "/publicpages/pages/support.html"' not in publicpages
privatepages = (app/'privatepages/privatepages.js').read_text()
assert 'LOCAL_FIRST_ROUTES = new Set(["/study", "/companion", "/profile"])' in privatepages
assert 'return path === "/support" || path === "/admin";' in privatepages
assert 'browser-local@buddies.local' in privatepages
assert '"/system"' not in privatepages
companion = (app/'privatepages/companion.js').read_text()
for token in ['DEFAULT_CLIPS', 'companionName', 'listeningVideoUrl', 'talkingVideoUrl', 'clipForState', 'reset-companion-media']:
    assert token in companion, token
profile = (app/'privatepages/pages/profile.html').read_text()
assert 'profileLocalFirstSettings' in profile
profile_js = (app/'privatepages/profile-local-first-settings.js').read_text()
assert 'apcLocalProfileSettings:' in profile_js
assert 'apcPrivateCompanionVoiceSettings:' in profile_js
support = (app/'privatepages/support.js').read_text()
assert '/system/support/tickets' in support
assert 'Authorization' in support
index = (app/'index.html').read_text()
assert 'profile-local-first-settings.js' in index
assert 'support.js' in index
home = (app/'publicpages/pages/home.html').read_text()
assert 'Local-first workspace' in home
assert 'href="/system"' not in home
print('PASS R16BU local-first route/support/profile/companion static checks')
PY

sha256sum \
  "$APP/index.html" \
  "$APP/header/header.html" \
  "$APP/header/header.nav" \
  "$APP/publicpages/publicpages.js" \
  "$APP/privatepages/privatepages.js" \
  "$APP/privatepages/companion.js" \
  "$APP/privatepages/pages/profile.html" \
  "$APP/privatepages/pages/support.html" \
  "$APP/privatepages/profile-local-first-settings.js" \
  "$APP/privatepages/support.js"

printf 'PASS stage-17k-r16bu-local-first-study-companion-profile-support-source-only smoke\n'
