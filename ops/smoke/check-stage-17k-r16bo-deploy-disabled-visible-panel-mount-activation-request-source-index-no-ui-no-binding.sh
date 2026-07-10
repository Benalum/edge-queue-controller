#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16bo-deploy-disabled-visible-panel-mount-activation-request-source-index-no-ui-no-binding"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
BASE_URL="https://buddieswhostudy.com"
ACTIVATION_CACHE_BUST="stage17k-r16bn-load-disabled-visible-panel-mount-activation-request-source-index-source-only-20260708"
fail() { echo "FAIL: $*" >&2; exit 1; }
line_for() { awk -v needle="$1" 'index($0, needle) { print NR; exit }' "$2"; }
printf '=== %s smoke ===\n' "$STAGE"
[ -f "$INDEX" ] || fail "missing source index"
for f in \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-mount-adapter.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-dom-template.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-slot-resolver.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-mount-controller.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-safe-mount-executor.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-mount-readiness-gate.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-dom-mount-candidate.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-mount-activation-request.js; do
  [ -f "$f" ] || fail "missing asset: $f"
done
visible_line="$(line_for 'study-card-images-disabled-visible-panel.js' "$INDEX")"
adapter_line="$(line_for 'study-card-images-disabled-visible-panel-mount-adapter.js' "$INDEX")"
dom_template_line="$(line_for 'study-card-images-disabled-visible-panel-dom-template.js' "$INDEX")"
slot_resolver_line="$(line_for 'study-card-images-disabled-visible-panel-slot-resolver.js' "$INDEX")"
mount_controller_line="$(line_for 'study-card-images-disabled-visible-panel-mount-controller.js' "$INDEX")"
safe_mount_line="$(line_for 'study-card-images-disabled-visible-panel-safe-mount-executor.js' "$INDEX")"
readiness_gate_line="$(line_for 'study-card-images-disabled-visible-panel-mount-readiness-gate.js' "$INDEX")"
dom_mount_candidate_line="$(line_for 'study-card-images-disabled-visible-panel-dom-mount-candidate.js' "$INDEX")"
activation_request_line="$(line_for 'study-card-images-disabled-visible-panel-mount-activation-request.js' "$INDEX")"
for name in visible_line adapter_line dom_template_line slot_resolver_line mount_controller_line safe_mount_line readiness_gate_line dom_mount_candidate_line activation_request_line; do
  [ -n "${!name}" ] || fail "missing line for $name"
done
if ! [ "$visible_line" -lt "$adapter_line" ] || ! [ "$adapter_line" -lt "$dom_template_line" ] || ! [ "$dom_template_line" -lt "$slot_resolver_line" ] || ! [ "$slot_resolver_line" -lt "$mount_controller_line" ] || ! [ "$mount_controller_line" -lt "$safe_mount_line" ] || ! [ "$safe_mount_line" -lt "$readiness_gate_line" ] || ! [ "$readiness_gate_line" -lt "$dom_mount_candidate_line" ] || ! [ "$dom_mount_candidate_line" -lt "$activation_request_line" ]; then
  fail "source index order mismatch"
fi
grep -qF "$ACTIVATION_CACHE_BUST" "$INDEX" || fail "source index cache bust missing"
grep -qF 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ACTIVATION_REQUEST_R16BM_SOURCE_ONLY' frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-mount-activation-request.js || fail "activation request marker missing"
printf 'PASS source index order visible < adapter < DOM template < slot resolver < mount controller < safe mount executor < readiness gate < DOM mount candidate < activation request visible_line=%s adapter_line=%s dom_template_line=%s slot_resolver_line=%s mount_controller_line=%s safe_mount_line=%s readiness_gate_line=%s dom_mount_candidate_line=%s activation_request_line=%s\n' "$visible_line" "$adapter_line" "$dom_template_line" "$slot_resolver_line" "$mount_controller_line" "$safe_mount_line" "$readiness_gate_line" "$dom_mount_candidate_line" "$activation_request_line"
if [ "${APC_R16BO_SKIP_PUBLIC:-0}" = "1" ]; then
  printf 'PASS %s source-only smoke public skipped\n' "$STAGE"
  exit 0
fi
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
curl -fsSL --max-time 25 "$BASE_URL/profile" -o "$tmp_dir/profile.html"
profile_code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$BASE_URL/profile")"
visible_code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$BASE_URL/privatepages/study-card-images-disabled-visible-panel.js")"
adapter_code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$BASE_URL/privatepages/study-card-images-disabled-visible-panel-mount-adapter.js")"
dom_template_code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$BASE_URL/privatepages/study-card-images-disabled-visible-panel-dom-template.js")"
slot_resolver_code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$BASE_URL/privatepages/study-card-images-disabled-visible-panel-slot-resolver.js")"
mount_controller_code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$BASE_URL/privatepages/study-card-images-disabled-visible-panel-mount-controller.js")"
safe_mount_code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$BASE_URL/privatepages/study-card-images-disabled-visible-panel-safe-mount-executor.js")"
readiness_gate_code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$BASE_URL/privatepages/study-card-images-disabled-visible-panel-mount-readiness-gate.js")"
dom_mount_candidate_code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$BASE_URL/privatepages/study-card-images-disabled-visible-panel-dom-mount-candidate.js")"
activation_request_code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$BASE_URL/privatepages/study-card-images-disabled-visible-panel-mount-activation-request.js")"
for pair in profile_code visible_code adapter_code dom_template_code slot_resolver_code mount_controller_code safe_mount_code readiness_gate_code dom_mount_candidate_code activation_request_code; do
  [ "${!pair}" = "200" ] || fail "public static $pair expected 200 got ${!pair}"
done
public_visible_line="$(line_for 'study-card-images-disabled-visible-panel.js' "$tmp_dir/profile.html")"
public_adapter_line="$(line_for 'study-card-images-disabled-visible-panel-mount-adapter.js' "$tmp_dir/profile.html")"
public_dom_template_line="$(line_for 'study-card-images-disabled-visible-panel-dom-template.js' "$tmp_dir/profile.html")"
public_slot_resolver_line="$(line_for 'study-card-images-disabled-visible-panel-slot-resolver.js' "$tmp_dir/profile.html")"
public_mount_controller_line="$(line_for 'study-card-images-disabled-visible-panel-mount-controller.js' "$tmp_dir/profile.html")"
public_safe_mount_line="$(line_for 'study-card-images-disabled-visible-panel-safe-mount-executor.js' "$tmp_dir/profile.html")"
public_readiness_gate_line="$(line_for 'study-card-images-disabled-visible-panel-mount-readiness-gate.js' "$tmp_dir/profile.html")"
public_dom_mount_candidate_line="$(line_for 'study-card-images-disabled-visible-panel-dom-mount-candidate.js' "$tmp_dir/profile.html")"
public_activation_request_line="$(line_for 'study-card-images-disabled-visible-panel-mount-activation-request.js' "$tmp_dir/profile.html")"
for name in public_visible_line public_adapter_line public_dom_template_line public_slot_resolver_line public_mount_controller_line public_safe_mount_line public_readiness_gate_line public_dom_mount_candidate_line public_activation_request_line; do
  [ -n "${!name}" ] || fail "missing public line for $name"
done
if ! [ "$public_visible_line" -lt "$public_adapter_line" ] || ! [ "$public_adapter_line" -lt "$public_dom_template_line" ] || ! [ "$public_dom_template_line" -lt "$public_slot_resolver_line" ] || ! [ "$public_slot_resolver_line" -lt "$public_mount_controller_line" ] || ! [ "$public_mount_controller_line" -lt "$public_safe_mount_line" ] || ! [ "$public_safe_mount_line" -lt "$public_readiness_gate_line" ] || ! [ "$public_readiness_gate_line" -lt "$public_dom_mount_candidate_line" ] || ! [ "$public_dom_mount_candidate_line" -lt "$public_activation_request_line" ]; then
  fail "public index order mismatch"
fi
grep -qF "$ACTIVATION_CACHE_BUST" "$tmp_dir/profile.html" || fail "public activation request cache bust missing"
api_system_status="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$BASE_URL/api/system/status")"
api_me_status="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$BASE_URL/api/me")"
signup_status="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 -X POST "$BASE_URL/api/auth/register" -H 'Content-Type: application/json' --data '{"email":"r16bo@example.invalid","password":"not-used"}')"
study_decks_status="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$BASE_URL/api/study/decks")"
[ "$api_system_status" = "200" ] || fail "api/system/status expected 200 got $api_system_status"
[ "$api_me_status" = "401" ] || fail "api/me expected 401 got $api_me_status"
[ "$signup_status" = "403" ] || fail "signup expected 403 got $signup_status"
[ "$study_decks_status" = "404" ] || fail "api/study/decks expected 404 got $study_decks_status"
printf 'PASS public static/API R16BO smoke profile=%s visible=%s adapter=%s dom_template=%s slot_resolver=%s mount_controller=%s safe_mount=%s readiness_gate=%s dom_mount_candidate=%s activation_request=%s api_system_status=%s api_me=%s signup=%s study_decks=%s\n' "$profile_code" "$visible_code" "$adapter_code" "$dom_template_code" "$slot_resolver_code" "$mount_controller_code" "$safe_mount_code" "$readiness_gate_code" "$dom_mount_candidate_code" "$activation_request_code" "$api_system_status" "$api_me_status" "$signup_status" "$study_decks_status"
printf 'PASS %s smoke\n' "$STAGE"
