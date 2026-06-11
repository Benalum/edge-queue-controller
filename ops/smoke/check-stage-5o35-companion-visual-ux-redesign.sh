#!/usr/bin/env bash

stage5o35_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"
  tmpdir="/tmp/stage5o35-smoke"
  mkdir -p "$tmpdir"

  echo "=== node syntax check ==="
  if node --check frontend/wrapper-ui/app.js; then
    echo "OK node syntax"
  else
    echo "FAIL node syntax"
    ok=0
  fi

  echo
  echo "=== wait for public status ==="
  ready=0
  i=1
  while [ "$i" -le 30 ]; do
    if curl -fsS "$base/api/system/public-status" > "$tmpdir/public-status.json" 2> "$tmpdir/public-status.err"; then
      ready=1
      break
    fi
    sleep 1
    i=$((i + 1))
  done

  if [ "$ready" = "1" ]; then
    echo "OK public-status"
    cat "$tmpdir/public-status.json"
    echo
  else
    echo "FAIL public-status"
    cat "$tmpdir/public-status.err" 2>/dev/null || true
    ok=0
  fi

  echo
  echo "=== route smoke ==="
  for route in /companion /chat /profile /study /support /credits /admin /system; do
    outfile="$tmpdir/${route////_}.html"
    code="$(curl -sS -L -o "$outfile" -w "%{http_code}" "$base$route" 2>> "$tmpdir/curl.err")"
    bytes="$(wc -c < "$outfile" 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== marker checks ==="
  if grep -q "STAGE_5O35_COMPANION_UX_BEGIN" frontend/wrapper-ui/app.js && grep -q "STAGE_5O35_COMPANION_UX_BEGIN" frontend/wrapper-ui/styles.css; then
    echo "OK Stage 5O-35 markers present"
  else
    echo "FAIL Stage 5O-35 markers missing"
    ok=0
  fi

  echo
  echo "=== recent journal signals ==="
  journalctl --user -n 120 --no-pager 2>/dev/null | grep -Ei "traceback|exception|failed|error" | tail -40 || true

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5O35_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5O35_SMOKE_FAIL"
  return 1
}

stage5o35_smoke_main "$@"
return 0 2>/dev/null || true
