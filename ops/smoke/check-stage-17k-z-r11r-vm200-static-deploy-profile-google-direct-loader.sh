#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r11r-vm200-static-deploy-profile-google-direct-loader.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r11r-vm200-static-deploy-profile-google-direct-loader"

test -f "$DOC"
test -d "$OUT_DIR"

grep -q "Controlled narrow VM200 static frontend deploy checkpoint" "$DOC"
grep -q "No wrapper" "$DOC"
grep -q "No bandage" "$DOC"
grep -q "No privatepages.js change" "$DOC"
grep -q "No Profile fragment change" "$DOC"
grep -q "No session gate change" "$DOC"
grep -q "No private shell change" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No DB write" "$DOC"
grep -q "No signup change" "$DOC"
grep -q "No Google Drive or OAuth activation" "$DOC"
grep -q "Only these three files were deployed" "$DOC"

test -f "$OUT_DIR/vm200-deploy."*.txt
test -f "$OUT_DIR/vm200-local-http-smoke."*.txt
test -f "$OUT_DIR/postdeploy-public-static-smoke."*.txt
test -f "$OUT_DIR/postdeploy-public-api-guard-smoke."*.txt

grep -q "R11R_VM200_THREE_FILE_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -q "PASS VM200 local R11R three-file static smoke" "$OUT_DIR/vm200-local-http-smoke."*.txt
grep -q "R11Q removed legacy Profile Google sync indirect loader" "$OUT_DIR/postdeploy-public-static-smoke."*.txt
grep -q "apc-private-page-rendered" "$OUT_DIR/postdeploy-public-static-smoke."*.txt
grep -q "api_system_status=200" "$OUT_DIR/postdeploy-public-api-guard-smoke."*.txt
grep -q "api_me_status=401" "$OUT_DIR/postdeploy-public-api-guard-smoke."*.txt
grep -q "signup_status=403" "$OUT_DIR/postdeploy-public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r11r VM200 static deploy Profile Google direct loader smoke"
