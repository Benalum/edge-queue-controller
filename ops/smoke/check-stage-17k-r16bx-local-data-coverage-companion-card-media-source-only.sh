#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-$(pwd)}"
cd "$ROOT"
APP="frontend/wrapper-ui/apc-wrapper-local"

printf '=== stage-17k-r16bx-local-data-coverage-companion-card-media-source-only smoke ===\n'

for f in \
  "$APP/index.html" \
  "$APP/privatepages/study-store.js" \
  "$APP/privatepages/local-data-coverage.js" \
  "$APP/privatepages/profile-companion-custom-media.js" \
  "$APP/privatepages/study-card-local-media.js" \
  "$APP/privatepages/companion-media-resolver.js" \
  "$APP/privatepages/companion-card-media-display.js" \
  "$APP/privatepages/profile-local-first-settings.js" \
  "$APP/privatepages/companion.js"; do
  test -f "$f" || { echo "FAIL missing $f"; exit 1; }
done

node --check "$APP/privatepages/study-store.js" >/dev/null
node --check "$APP/privatepages/local-data-coverage.js" >/dev/null
node --check "$APP/privatepages/profile-companion-custom-media.js" >/dev/null
node --check "$APP/privatepages/study-card-local-media.js" >/dev/null
node --check "$APP/privatepages/companion-media-resolver.js" >/dev/null
node --check "$APP/privatepages/companion-card-media-display.js" >/dev/null

python3 - <<'PY'
from pathlib import Path
app = Path('frontend/wrapper-ui/apc-wrapper-local')
index = (app/'index.html').read_text()
study_store = (app/'privatepages/study-store.js').read_text()
coverage = (app/'privatepages/local-data-coverage.js').read_text()
profile_media = (app/'privatepages/profile-companion-custom-media.js').read_text()
study_media = (app/'privatepages/study-card-local-media.js').read_text()
companion_media = (app/'privatepages/companion-media-resolver.js').read_text()
companion_card = (app/'privatepages/companion-card-media-display.js').read_text()

required_scripts = [
  'study-card-local-media.js',
  'local-data-coverage.js',
  'profile-companion-custom-media.js',
  'companion-media-resolver.js',
  'companion-card-media-display.js',
]
for script in required_scripts:
    assert script in index, f'missing script tag {script}'

assert 'APC_STUDY_STORE_CARD_MEDIA_REFS_R16BX' in study_store
assert 'frontImage' in study_store and 'backImage' in study_store
assert 'function createCard(deckId, front, back, difficulty, media)' in study_store
assert 'APC_LOCAL_DATA_COVERAGE_R16BX_FULL_LOCAL_BACKUP' in coverage
assert 'includesStudyDecks: true' in coverage
assert 'includesCompanionClips: true' in coverage
assert 'includesLocalBlobDataUrls: true' in coverage
assert 'writesAnkiFiles: false' in coverage
assert 'APC_PROFILE_COMPANION_CUSTOM_MEDIA_R16BX' in profile_media
assert 'data-apc-companion-media-file="listening"' in profile_media
assert 'data-apc-companion-media-file="talking"' in profile_media
assert 'APC_STUDY_CARD_LOCAL_MEDIA_R16BX_FRONT_BACK_IMAGES' in study_media
assert 'data-apc-study-new-card-image="front"' in study_media
assert 'data-apc-study-new-card-image="back"' in study_media
assert 'APC_COMPANION_MEDIA_RESOLVER_R16BX' in companion_media
assert 'APC_COMPANION_CARD_MEDIA_DISPLAY_R16BX' in companion_card
assert 'pendingSelfAssessment' in companion_card
print('PASS R16BX local data coverage, custom companion media, and study card image static checks')
PY

sha256sum \
  "$APP/index.html" \
  "$APP/privatepages/study-store.js" \
  "$APP/privatepages/local-data-coverage.js" \
  "$APP/privatepages/profile-companion-custom-media.js" \
  "$APP/privatepages/study-card-local-media.js" \
  "$APP/privatepages/companion-media-resolver.js" \
  "$APP/privatepages/companion-card-media-display.js"

printf 'PASS stage-17k-r16bx-local-data-coverage-companion-card-media-source-only smoke\n'
