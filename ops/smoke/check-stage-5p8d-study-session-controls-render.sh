#!/usr/bin/env bash

stage5p8d_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="${STAGE5P8D_BASE:-http://127.0.0.1:8787}"
  tmpdir="/tmp/stage5p8d-study-controls-render"
  mkdir -p "$tmpdir"

  echo "=== Stage 5P-8D Study Session Controls Render Smoke ==="
  echo "base=$base"

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0

  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== source marker checks ==="
  for marker in \
    "STAGE_5P8A_STUDY_SESSION_STATUS_CARD_BEGIN" \
    "stage5p8a-study-session-status-card" \
    "STAGE_5P8C_STUDY_SESSION_CONTROL_BUTTONS_BEGIN" \
    "stage5p8c-study-session-controls" \
    "Study Session Pause" \
    "Study Session Resume" \
    "Study Session Stop" \
    "Start is intentionally not wired yet"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css; then
      echo "OK source marker $marker"
    else
      echo "FAIL missing source marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== wrapper reachability ==="
  if curl -fsS "$base/api/system/public-status" > "$tmpdir/public-status.json"; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  echo
  echo "=== route smoke ==="
  for route in /study /companion /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o "$tmpdir/route.html" -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < "$tmpdir/route.html" 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== fetch /study and live assets ==="
  code="$(curl -sS -L -o "$tmpdir/study.html" -w "%{http_code}" "$base/study" || true)"
  bytes="$(wc -c < "$tmpdir/study.html" 2>/dev/null || printf 0)"

  if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
    echo "OK /study fetch code=$code bytes=$bytes"
  else
    echo "FAIL /study fetch code=$code bytes=$bytes"
    ok=0
  fi

  app_src="$(grep -oE 'src="[^"]*/?app\.js\?v=[^"]*"' "$tmpdir/study.html" | head -1 | sed -E 's/src="([^"]+)"/\1/' || true)"
  css_src="$(grep -oE 'href="[^"]*/?styles\.css\?v=[^"]*"' "$tmpdir/study.html" | grep -v '/study/styles.css' | head -1 | sed -E 's/href="([^"]+)"/\1/' || true)"

  if [ -z "$app_src" ]; then app_src="/app.js"; fi
  if [ -z "$css_src" ]; then css_src="/styles.css"; fi

  case "$app_src" in
    http://*|https://*) app_url="$app_src" ;;
    /*) app_url="$base$app_src" ;;
    ./*) app_url="$base/${app_src#./}" ;;
    *) app_url="$base/$app_src" ;;
  esac

  case "$css_src" in
    http://*|https://*) css_url="$css_src" ;;
    /*) css_url="$base$css_src" ;;
    ./*) css_url="$base/${css_src#./}" ;;
    *) css_url="$base/$css_src" ;;
  esac

  echo "app_url=$app_url"
  echo "css_url=$css_url"

  if curl -fsS "$app_url" > "$tmpdir/live-app.js"; then
    echo "OK fetched live app.js"
  else
    echo "FAIL fetch live app.js"
    ok=0
  fi

  if curl -fsS "$css_url" > "$tmpdir/live-styles.css"; then
    echo "OK fetched live styles.css"
  else
    echo "FAIL fetch live styles.css"
    ok=0
  fi

  for marker in \
    "STAGE_5P8C_STUDY_SESSION_CONTROL_BUTTONS_BEGIN" \
    "stage5p8c-study-session-controls" \
    "Study Session Pause" \
    "Study Session Resume" \
    "Study Session Stop"
  do
    if grep -R -Fq "$marker" "$tmpdir/live-app.js" "$tmpdir/live-styles.css"; then
      echo "OK live asset marker $marker"
    else
      echo "FAIL missing live asset marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== optional browser render check ==="
  if [ -d node_modules/@playwright/test ] || npm ls @playwright/test >/dev/null 2>&1; then
    cat > "$tmpdir/stage5p8d-render-check.js" <<'JS'
const { chromium } = require('@playwright/test');

(async () => {
  const base = process.env.STAGE5P8D_BASE || 'http://127.0.0.1:8787';
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto(base + '/study', { waitUntil: 'networkidle' });
  await page.waitForTimeout(1200);

  const statusCard = await page.locator('#stage5p8a-study-session-status-card').count();
  const controls = await page.locator('.stage5p8c-study-session-controls').count();
  const refresh = await page.locator('.stage5p8c-study-session-controls button', { hasText: 'Refresh' }).count();
  const pause = await page.locator('.stage5p8c-study-session-controls button', { hasText: 'Pause' }).count();
  const resume = await page.locator('.stage5p8c-study-session-controls button', { hasText: 'Resume' }).count();
  const stop = await page.locator('.stage5p8c-study-session-controls button', { hasText: 'Stop' }).count();

  console.log(JSON.stringify({ statusCard, controls, refresh, pause, resume, stop }, null, 2));

  if (!statusCard || !controls || !refresh || !pause || !resume || !stop) {
    throw new Error('Stage 5P-8C controls did not render.');
  }

  await browser.close();
})();
JS

    if node "$tmpdir/stage5p8d-render-check.js"; then
      echo "OK Playwright render check"
    else
      echo "FAIL Playwright render check"
      ok=0
    fi
  else
    echo "Playwright not installed. Skipping optional browser-render check."
    echo "Static live-asset checks above still prove Stage 5P-8C code is being served."
  fi

  echo
  echo "=== recent journal signals ==="
  journalctl --user -n 120 --no-pager 2>/dev/null | grep -Ei "traceback|exception|failed|error" | tail -30 || true

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P8D_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P8D_SMOKE_FAIL"
  return 1
}

if stage5p8d_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
