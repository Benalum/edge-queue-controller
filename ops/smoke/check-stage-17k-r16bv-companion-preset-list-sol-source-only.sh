#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-$(pwd)}"
cd "$ROOT"
APP="frontend/wrapper-ui/apc-wrapper-local"

printf '=== stage-17k-r16bv-companion-preset-list-sol-source-only smoke ===\n'

for f in \
  "$APP/index.html" \
  "$APP/privatepages/companion-presets.js" \
  "$APP/privatepages/pages/study.html" \
  "$APP/privatepages/companion.js" \
  "$APP/privatepages/profile-local-first-settings.js"; do
  test -f "$f" || { echo "FAIL missing $f"; exit 1; }
done

node --check "$APP/privatepages/companion-presets.js" >/dev/null
node --check "$APP/privatepages/companion.js" >/dev/null
node --check "$APP/privatepages/profile-local-first-settings.js" >/dev/null

python3 - <<'PY'
from pathlib import Path
app = Path('frontend/wrapper-ui/apc-wrapper-local')
index = (app/'index.html').read_text()
presets = (app/'privatepages/companion-presets.js').read_text()
study = (app/'privatepages/pages/study.html').read_text()
assert 'companion-presets.js' in index
assert 'APC_COMPANION_PRESETS_R16BV_SOL_SOURCE_ONLY' in presets
assert 'const PRESETS = [' in presets
assert 'id: "sol"' in presets
assert 'label: "Sol"' in presets
assert 'Current built-in list: Sol.' in presets
assert 'apcPrivateCompanionVoiceSettings:' in presets
assert 'data-apc-companion-preset-select' in presets
assert 'Custom / my own media' in presets
assert 'studyPrivateApp' in study
assert 'Study locally' in study
assert '/system' not in (app/'header/header.nav').read_text()
assert 'System' not in (app/'header/header.html').read_text()
print('PASS R16BV companion preset list and study fragment static checks')
PY

sha256sum \
  "$APP/index.html" \
  "$APP/privatepages/companion-presets.js" \
  "$APP/privatepages/pages/study.html" \
  "$APP/privatepages/assets/sol-clips/README.md"

find "$APP/privatepages/assets/sol-clips" -maxdepth 1 -type f -name '*.mp4' -print0 | sort -z | xargs -0 -r sha256sum

printf 'PASS stage-17k-r16bv-companion-preset-list-sol-source-only smoke\n'
