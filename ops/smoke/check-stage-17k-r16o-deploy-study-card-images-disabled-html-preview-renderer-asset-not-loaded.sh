#!/usr/bin/env bash
set -euo pipefail
PUBLIC_BASE="https://buddieswhostudy.com"
ASSET_PATH="/privatepages/study-card-images-disabled-html-preview-renderer.js"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_HTML_PREVIEW_RENDERER_R16N_SOURCE_ONLY"
CACHE_BUST="stage17k-r16o-smoke-$(date -u +%Y%m%dT%H%M%SZ)"

echo "=== stage-17k-r16o deploy disabled image html preview renderer asset not loaded smoke ==="
profile_root_code=$(curl -sS -o /tmp/apc-r16o-profile-root.html -w "%{http_code}" "${PUBLIC_BASE}/profile?v=${CACHE_BUST}")
asset_code=$(curl -sS -o /tmp/apc-r16o-disabled-html-preview-renderer.js -w "%{http_code}" "${PUBLIC_BASE}${ASSET_PATH}?v=${CACHE_BUST}")
profile_root_bytes=$(wc -c < /tmp/apc-r16o-profile-root.html | tr -d ' ')
asset_bytes=$(wc -c < /tmp/apc-r16o-disabled-html-preview-renderer.js | tr -d ' ')
echo "profile_root_code=${profile_root_code} profile_root_bytes=${profile_root_bytes}"
echo "asset_code=${asset_code} asset_bytes=${asset_bytes}"
if [ "$profile_root_code" != "200" ]; then echo "FAIL: /profile not 200"; exit 1; fi
if [ "$asset_code" != "200" ]; then echo "FAIL: asset not 200"; exit 1; fi
if ! grep -Fq "$MARKER" /tmp/apc-r16o-disabled-html-preview-renderer.js; then echo "FAIL: marker missing from public asset"; exit 1; fi
if grep -Fq "$ASSET_PATH" /tmp/apc-r16o-profile-root.html || grep -Fq "study-card-images-disabled-html-preview-renderer.js" /tmp/apc-r16o-profile-root.html; then
  echo "FAIL: /profile loads disabled html preview renderer asset"
  exit 1
fi
if grep -Eqi 'add image|upload image|choose image|question image|answer image|remove image|save image|store image' /tmp/apc-r16o-profile-root.html; then
  echo "FAIL: unsafe image UI wording found in profile root"
  exit 1
fi
echo "PASS public static disabled image html preview renderer asset-not-loaded smoke"
