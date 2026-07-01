#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r11m-r4-bounded-push-recovery-no-fetch.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r11m-r4-bounded-push-recovery-no-fetch"
R11M_R2_TAG="controller-stage-17k-z-r11m-r2-remove-duplicate-profile-render-path-source-2026-07-01"

test -f "$DOC"
test -d "$OUT_DIR"

grep -q "Push recovery checkpoint" "$DOC"
grep -q "No deploy" "$DOC"
grep -q "No frontend live mutation" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No Google Drive or OAuth activation" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No local Study doc write" "$DOC"
grep -q "No real SQLite collection parsing" "$DOC"
grep -q "No media extraction" "$DOC"

test -f "$OUT_DIR/r11m-r2-smoke."*.txt
test -f "$OUT_DIR/push-r11m-r2-main."*.txt
test -f "$OUT_DIR/push-r11m-r2-tag."*.txt

grep -q "PASS stage-17k-z-r11m-r2 remove duplicate Profile render path source smoke" "$OUT_DIR/r11m-r2-smoke."*.txt
grep -q "push_main_exit=0" "$OUT_DIR/push-r11m-r2-main."*.txt
grep -q "push_tag_exit=0" "$OUT_DIR/push-r11m-r2-tag."*.txt

git merge-base --is-ancestor 2a7fe0a HEAD
git tag --points-at 2a7fe0a | grep -qx "$R11M_R2_TAG"

echo "PASS stage-17k-z-r11m-r4 bounded push recovery smoke"
