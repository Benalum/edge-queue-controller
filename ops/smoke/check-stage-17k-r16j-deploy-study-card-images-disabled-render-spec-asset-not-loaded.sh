#!/usr/bin/env bash
set -Eeuo pipefail
BASE_URL="${BASE_URL:-https://buddieswhostudy.com}"
SRC_ROOT="frontend/wrapper-ui/apc-wrapper-local"
INDEX="$SRC_ROOT/index.html"
ASSET_REL="privatepages/study-card-images-disabled-render-spec.js"
ASSET="$SRC_ROOT/$ASSET_REL"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_RENDER_SPEC_R16I_SOURCE_ONLY"
CACHEBUST="stage17k-r16j-disabled-image-render-spec-asset-not-loaded-20260708"

has_forbidden_static_pattern() {
  local file="$1"
  local patterns=(
    'document.'
    'appendChild'
    'insertAdjacentElement'
    'addEventListener("click'
    "addEventListener('click"
    'onclick'
    'fetch('
    'XMLHttpRequest'
    'sendBeacon'
    'localStorage'
    'sessionStorage'
    'indexedDB'
    'FileReader'
    'createObjectURL'
    'showOpenFilePicker'
    'showSaveFilePicker'
    'showDirectoryPicker'
    'createWritable('
    '.write('
    '.close('
  )
  local pattern
  for pattern in "${patterns[@]}"; do
    if grep -Fq "$pattern" "$file"; then
      echo "forbidden_pattern=$pattern"
      return 0
    fi
  done
  return 1
}

echo "=== stage-17k-r16j deploy disabled image render spec asset not loaded smoke ==="
test -f "$ASSET"
grep -Fq "$MARKER" "$ASSET"
if grep -Fq "$ASSET_REL" "$INDEX"; then
  echo "FAIL: index.html loads disabled render spec asset"
  exit 1
fi
if has_forbidden_static_pattern "$ASSET"; then
  echo "FAIL: forbidden DOM/write/network/file API in disabled render spec asset"
  exit 1
fi

tmp_profile="$(mktemp)"
tmp_asset="$(mktemp)"
trap 'rm -f "$tmp_profile" "$tmp_asset"' EXIT
profile_code="$(curl -sS -L -o "$tmp_profile" -w '%{http_code}' "$BASE_URL/profile?stage17k_r16j=$CACHEBUST")"
asset_code="$(curl -sS -L -o "$tmp_asset" -w '%{http_code}' "$BASE_URL/$ASSET_REL?v=$CACHEBUST-$(date -u +%Y%m%dT%H%M%SZ)")"
echo "profile_root_code=$profile_code profile_root_bytes=$(wc -c < "$tmp_profile")"
echo "asset_code=$asset_code asset_bytes=$(wc -c < "$tmp_asset")"
if [ "$profile_code" != "200" ]; then echo "FAIL: profile root non-200"; exit 1; fi
if [ "$asset_code" != "200" ]; then echo "FAIL: disabled render spec asset non-200"; exit 1; fi
if grep -Fq "$ASSET_REL" "$tmp_profile"; then
  echo "FAIL: profile root loads disabled render spec asset"
  exit 1
fi
grep -Fq "$MARKER" "$tmp_asset" || { echo "FAIL: marker missing from public asset"; exit 1; }
if grep -Eiq '<!doctype html|<html' "$tmp_asset"; then
  echo "FAIL: public asset returned HTML fallback"
  exit 1
fi
if has_forbidden_static_pattern "$tmp_asset"; then
  echo "FAIL: forbidden DOM/write/network/file API in public disabled render spec asset"
  exit 1
fi

echo "PASS public static disabled render spec asset-not-loaded smoke"
