#!/usr/bin/env bash
set -euo pipefail
set +H

echo "=== Phase 14J-KA smoke: public PVEW bridge checkpoint ==="
echo "MUTATION_SCOPE=none_read_only"
echo "NO SSH"
echo "NO live infra mutation"

probe_html() {
  url="$1"
  out="$(mktemp)"
  code="$(curl -k -L -sS -m 15 -o "$out" -w "%{http_code}" "$url" || true)"
  title="$(grep -Eio '<title>[^<]+' "$out" 2>/dev/null | head -1 | sed 's/<title>//I' || true)"
  echo "html_probe url=$url http=$code title=${title:-none}"
  test "$code" = "200"
  grep -q "AlexHartel AI Platform" "$out"
  rm -f "$out"
}

probe_json() {
  url="$1"
  expected="$2"
  out="$(mktemp)"
  code="$(curl -k -L -sS -m 15 -o "$out" -w "%{http_code}" "$url" || true)"
  bytes="$(wc -c < "$out" 2>/dev/null || echo 0)"
  echo "json_probe url=$url http=$code bytes=$bytes"
  test "$code" = "$expected"
  rm -f "$out"
}

probe_html "https://alexhartel.com/"
probe_html "https://alexhartel.com/system"
probe_html "https://alexhartel.com/study"
probe_html "https://alexhartel.com/companion"
probe_html "https://alexhartel.com/profile"
probe_html "https://alexhartel.com/credits"

probe_json "https://alexhartel.com/public/status" "200"
probe_json "https://alexhartel.com/system/local-health" "200"

echo "PASS_PHASE_14J_KA_PUBLIC_PVEW_BRIDGE_CHECKPOINT"
