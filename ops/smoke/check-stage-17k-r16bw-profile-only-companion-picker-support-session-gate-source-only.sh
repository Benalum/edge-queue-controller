#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-$(pwd)}"
cd "$ROOT"
APP="frontend/wrapper-ui/apc-wrapper-local"

printf '=== stage-17k-r16bw-profile-only-companion-picker-support-session-gate-source-only smoke ===\n'

for f in \
  "$APP/index.html" \
  "$APP/privatepages/companion.js" \
  "$APP/privatepages/companion-presets.js" \
  "$APP/privatepages/profile-local-first-settings.js" \
  "$APP/privatepages/support.js" \
  "$APP/privatepages/pages/study.html" \
  "$APP/privatepages/pages/companion.html" \
  "$APP/privatepages/pages/profile.html" \
  "$APP/privatepages/pages/support.html"; do
  test -f "$f" || { echo "FAIL missing $f"; exit 1; }
done

node --check "$APP/privatepages/companion.js" >/dev/null
node --check "$APP/privatepages/companion-presets.js" >/dev/null
node --check "$APP/privatepages/profile-local-first-settings.js" >/dev/null
node --check "$APP/privatepages/support.js" >/dev/null

python3 - <<'PY'
from pathlib import Path
app = Path('frontend/wrapper-ui/apc-wrapper-local')
index = (app/'index.html').read_text()
presets = (app/'privatepages/companion-presets.js').read_text()
companion = (app/'privatepages/companion.js').read_text()
profile = (app/'privatepages/profile-local-first-settings.js').read_text()

assert 'APC_SESSION_CHECK_ROUTES' in index
assert "'/support': true" in index
assert "'/admin': true" in index
assert "releaseGate('local_first')" in index
assert '!/(support|admin)/i.test(marker)' in index
assert 'study|companion|profile|calendar|account|dashboard|private' not in index
assert "content: 'Checking session...'" in index  # still available for Support/Admin only

assert 'APC_COMPANION_PRESETS_R16BW_PROFILE_ONLY_SOL_SOURCE_ONLY' in presets
assert 'function renderIntoProfile()' in presets
assert 'function renderIntoCompanion()' in presets
assert 'Companion selection lives only in Profile' in presets
assert 'renderIntoCompanion();' not in presets
assert 'personalBox.insertAdjacentHTML("afterbegin", selectHtml("companion"))' not in presets
assert 'id: "sol"' in presets and 'label: "Sol"' in presets

assert 'users choose companion presets and media in Profile only' in companion
assert 'function renderPersonalizationBox(settings)' in companion
assert 'return "";' in companion
assert '${renderPersonalizationBox(settings)}' not in companion
assert 'Companion name</label>' not in companion
assert 'Listening video URL</label>' not in companion
assert 'Talking video URL</label>' not in companion

assert 'profileCompanionName' in profile
assert 'profileCompanionListeningVideo' in profile
assert 'profileCompanionTalkingVideo' in profile
print('PASS R16BW profile-only companion picker and support-only session gate static checks')
PY

sha256sum \
  "$APP/index.html" \
  "$APP/privatepages/companion.js" \
  "$APP/privatepages/companion-presets.js" \
  "$APP/privatepages/profile-local-first-settings.js" \
  "$APP/privatepages/support.js" \
  "$APP/privatepages/pages/study.html" \
  "$APP/privatepages/pages/companion.html" \
  "$APP/privatepages/pages/profile.html" \
  "$APP/privatepages/pages/support.html"

printf 'PASS stage-17k-r16bw-profile-only-companion-picker-support-session-gate-source-only smoke\n'
