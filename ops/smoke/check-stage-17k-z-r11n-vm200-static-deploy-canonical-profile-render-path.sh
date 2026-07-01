#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r11n-vm200-static-deploy-canonical-profile-render-path.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r11n-vm200-static-deploy-canonical-profile-render-path"

test -f "$DOC"
test -d "$OUT_DIR"

grep -q "Controlled VM200 static frontend deploy checkpoint" "$DOC"
grep -q "Deployed the R11M-R2 canonical Profile source fix" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No DB write" "$DOC"
grep -q "No signup change" "$DOC"
grep -q "No Google Drive or OAuth activation" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No local Study doc write" "$DOC"
grep -q "No real SQLite collection parsing" "$DOC"
grep -q "No media extraction" "$DOC"
grep -q "No service restart" "$DOC"

test -f "$OUT_DIR/vm200-deploy."*.txt
test -f "$OUT_DIR/vm200-local-http-smoke."*.txt
test -f "$OUT_DIR/postdeploy-public-static-smoke."*.txt
test -f "$OUT_DIR/postdeploy-public-api-guard-smoke."*.txt

grep -q "R11N_VM200_STATIC_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -q "PASS VM200 local canonical Profile static smoke" "$OUT_DIR/vm200-local-http-smoke."*.txt
grep -q "R11M-R2 removed legacy Google sync Profile loader" "$OUT_DIR/postdeploy-public-static-smoke."*.txt
grep -q "apc-private-page-rendered" "$OUT_DIR/postdeploy-public-static-smoke."*.txt
grep -q "data-apc-profile-google-sync-host" "$OUT_DIR/postdeploy-public-static-smoke."*.txt
grep -q "api_system_status=200" "$OUT_DIR/postdeploy-public-api-guard-smoke."*.txt
grep -q "api_me_status=401" "$OUT_DIR/postdeploy-public-api-guard-smoke."*.txt
grep -q "signup_status=403" "$OUT_DIR/postdeploy-public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r11n VM200 static deploy canonical Profile render path smoke"
