#!/usr/bin/env bash

stage5o36_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  echo "=== Stage 5O-36 checkpoint before changes ==="
  git status --short
  git rev-parse --short HEAD
  git tag --points-at HEAD || true

  echo
  echo "=== Create Stage 5O-36 docs and smoke ==="
  mkdir -p docs ops/smoke ops/stage

  cat > docs/stage-5o36-companion-browser-render-regression-smoke.md <<'MD'
# Stage 5O-36 Companion Browser Render Regression Smoke

## Purpose

Stage 5O-36 adds a regression smoke for the Stage 5O-35 Companion visual UX redesign.

The normal route smoke confirms the wrapper serves `/companion`, but it does not prove that the browser-loaded JavaScript enhanced the page. This smoke checks the shipped assets and, when browser tooling is available, verifies the rendered Companion UI includes the Stage 5O-35 shell.

## Scope

- Test-only stage.
- No runtime behavior changes.
- No backend route changes.
- No queue behavior changes.
- No auth/header behavior changes.
- No local calendar database.

## What is checked

- `frontend/wrapper-ui/app.js` syntax.
- Stage 5O-35 markers exist in app and CSS.
- `index.html` references cache-busted `app.js` and `styles.css`.
- `/companion` is reachable from the local wrapper.
- The live `app.js` and `styles.css` served by the wrapper contain Stage 5O-35 markers.
- Optional browser-render check if Playwright is available.
MD

  cat > ops/smoke/check-stage-5o36-companion-browser-render-regression-smoke.sh <<'SMOKE'
#!/usr/bin/env bash

stage5o36_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="${STAGE5O36_BASE:-http://127.0.0.1:8787}"
  tmpdir="/tmp/stage5o36-companion-render"
  mkdir -p "$tmpdir"

  echo "=== Stage 5O-36 Companion browser/render regression smoke ==="
  echo "base=$base"

  echo
  echo "=== node syntax ==="
  if node --check frontend/wrapper-ui/app.js; then
    echo "OK node syntax"
  else
    echo "FAIL node syntax"
    ok=0
  fi

  echo
  echo "=== source marker checks ==="
  if grep -q "STAGE_5O35_COMPANION_UX_BEGIN" frontend/wrapper-ui/app.js; then
    echo "OK app.js Stage 5O-35 marker"
  else
    echo "FAIL app.js Stage 5O-35 marker missing"
    ok=0
  fi

  if grep -q "STAGE_5O35_COMPANION_UX_BEGIN" frontend/wrapper-ui/styles.css; then
    echo "OK styles.css Stage 5O-35 marker"
  else
    echo "FAIL styles.css Stage 5O-35 marker missing"
    ok=0
  fi

  echo
  echo "=== index asset references ==="
  grep -nE 'app\.js|styles\.css' frontend/wrapper-ui/index.html || true

  if grep -Eq 'app\.js\?v=[0-9]+' frontend/wrapper-ui/index.html; then
    echo "OK app.js cache-busted"
  else
    echo "FAIL app.js cache-bust missing"
    ok=0
  fi

  if grep -Eq 'styles\.css\?v=[0-9]+' frontend/wrapper-ui/index.html; then
    echo "OK styles.css cache-busted"
  else
    echo "FAIL styles.css cache-bust missing"
    ok=0
  fi

  echo
  echo "=== wrapper reachability ==="
  if curl -fsS "$base/api/system/public-status" > "$tmpdir/public-status.json"; then
    echo "OK public-status"
    cat "$tmpdir/public-status.json"
    echo
  else
    echo "FAIL public-status"
    ok=0
  fi

  echo
  echo "=== companion route fetch ==="
  companion_code="$(curl -sS -L -o "$tmpdir/companion.html" -w "%{http_code}" "$base/companion" 2> "$tmpdir/companion.err" || true)"
  companion_bytes="$(wc -c < "$tmpdir/companion.html" 2>/dev/null || printf 0)"
  echo "companion_code=$companion_code companion_bytes=$companion_bytes"
  if [ "$companion_code" = "200" ] && [ "$companion_bytes" -gt 100 ]; then
    echo "OK companion route"
  else
    echo "FAIL companion route"
    cat "$tmpdir/companion.err" 2>/dev/null || true
    ok=0
  fi

  echo
  echo "=== live asset marker checks ==="
  app_src="$(grep -oE 'src="[^"]*/?app\.js\?v=[^"]*"' "$tmpdir/companion.html" | head -1 | sed -E 's/src="([^"]+)"/\1/' || true)"
  css_src="$(grep -oE 'href="[^"]*/?styles\.css\?v=[^"]*"' "$tmpdir/companion.html" | grep -v '/study/styles.css' | head -1 | sed -E 's/href="([^"]+)"/\1/' || true)"

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

  echo "app_src=$app_src"
  echo "css_src=$css_src"
  echo "app_url=$app_url"
  echo "css_url=$css_url"

  if curl -fsS "$app_url" -o "$tmpdir/live-app.js" && grep -q "STAGE_5O35_COMPANION_UX_BEGIN" "$tmpdir/live-app.js"; then
    echo "OK live app.js contains Stage 5O-35 marker"
  else
    echo "FAIL live app.js marker missing"
    ok=0
  fi

  if curl -fsS "$css_url" -o "$tmpdir/live-styles.css" && grep -q "STAGE_5O35_COMPANION_UX_BEGIN" "$tmpdir/live-styles.css"; then
    echo "OK live styles.css contains Stage 5O-35 marker"
  else
    echo "FAIL live styles.css marker missing"
    ok=0
  fi

  echo
  echo "=== optional browser-render check ==="
  if node -e "require('playwright')" >/dev/null 2>&1; then
    echo "Playwright found. Running rendered DOM check."
    cat > "$tmpdir/check-render.js" <<'NODE'
const { chromium } = require("playwright");

(async () => {
  const base = process.env.STAGE5O36_BASE || "http://127.0.0.1:8787";
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  const errors = [];
  page.on("pageerror", err => errors.push(String(err && err.message ? err.message : err)));
  page.on("console", msg => {
    if (msg.type() === "error") errors.push(msg.text());
  });

  await page.goto(`${base}/companion`, { waitUntil: "networkidle", timeout: 15000 });
  await page.waitForTimeout(500);

  const data = await page.evaluate(() => {
    const text = document.body ? document.body.innerText : "";
    const shell = document.querySelector(".stage5o35-companion-shell");
    return {
      title: document.title,
      hasShell: Boolean(shell),
      hasHero: Boolean(document.querySelector(".stage5o35-companion-hero")),
      hasGrid: Boolean(document.querySelector(".stage5o35-companion-grid")),
      hasConversationCard: Boolean(document.querySelector(".stage5o35-conversation-card")),
      hasStatusCard: Boolean(document.querySelector(".stage5o35-status-card")),
      hasStudyPlaceholder: /Study context/i.test(text),
      hasQueuedCopy: /queued chat|queue-aware|Queue/i.test(text),
      bodySample: text.slice(0, 500)
    };
  });

  await browser.close();

  console.log(JSON.stringify({ data, errors }, null, 2));

  if (!data.hasShell || !data.hasHero || !data.hasGrid || !data.hasConversationCard || !data.hasStatusCard) {
    process.exit(2);
  }

  if (errors.length) {
    process.exit(3);
  }
})();
NODE

    if STAGE5O36_BASE="$base" node "$tmpdir/check-render.js"; then
      echo "OK browser-render Companion UI check"
    else
      echo "FAIL browser-render Companion UI check"
      ok=0
    fi
  else
    echo "Playwright not installed for this repo/user. Skipping optional browser-render check."
    echo "Static live-asset checks above still prove the Stage 5O-35 code is being served."
  fi

  echo
  echo "=== broad route smoke ==="
  for route in /companion /chat /profile /study /support /credits /admin /system; do
    outfile="$tmpdir/${route////_}.html"
    code="$(curl -sS -L -o "$outfile" -w "%{http_code}" "$base$route" 2>> "$tmpdir/routes.err" || true)"
    bytes="$(wc -c < "$outfile" 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== recent journal signals ==="
  journalctl --user -n 120 --no-pager 2>/dev/null | grep -Ei "traceback|exception|failed|error" | tail -40 || true

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5O36_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5O36_SMOKE_FAIL"
  return 1
}

stage5o36_smoke_main "$@"
return 0 2>/dev/null || true
SMOKE

  chmod +x ops/smoke/check-stage-5o36-companion-browser-render-regression-smoke.sh

  echo
  echo "=== Run Stage 5O-36 smoke ==="
  stage_ok=1
  if bash ops/smoke/check-stage-5o36-companion-browser-render-regression-smoke.sh; then
    echo "OK Stage 5O-36 smoke"
  else
    echo "FAIL Stage 5O-36 smoke"
    stage_ok=0
  fi

  echo
  echo "=== Git diff summary ==="
  git diff -- docs/stage-5o36-companion-browser-render-regression-smoke.md \
              ops/smoke/check-stage-5o36-companion-browser-render-regression-smoke.sh \
              ops/stage/apply-stage-5o36-companion-render-smoke.sh | sed -n '1,260p'

  echo
  echo "=== Commit and tag when checks pass ==="
  if [ "$stage_ok" = "1" ]; then
    git add docs/stage-5o36-companion-browser-render-regression-smoke.md \
            ops/smoke/check-stage-5o36-companion-browser-render-regression-smoke.sh \
            ops/stage/apply-stage-5o36-companion-render-smoke.sh

    if git diff --cached --quiet; then
      echo "No staged changes found."
    else
      git commit -m "test: add companion render smoke stage 5o36"
    fi

    tag="controller-stage-5o36-companion-browser-render-regression-smoke-2026-06-11"
    if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
      echo "Tag already exists: $tag"
    else
      git tag "$tag"
      echo "Created tag: $tag"
    fi
  else
    echo "Checks failed. No commit/tag attempted."
  fi

  echo
  echo "=== Final checkpoint ==="
  git status --short
  git rev-parse --short HEAD
  git tag --points-at HEAD || true

  return 0
}

stage5o36_main "$@"
return 0 2>/dev/null || true
