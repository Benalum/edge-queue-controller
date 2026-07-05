#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13p-download-snapshot-handler-inventory-read-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13p-download-snapshot-handler-inventory-read-only"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Download Snapshot Handler Inventory Read-Only" "$DOC"
grep -Fq "No source mutation" "$DOC"
grep -Fq "No browser download behavior change" "$DOC"
grep -Fq "No same-file write path" "$DOC"

test -s "$OUT_DIR/panel-download-grep."*.txt
test -s "$OUT_DIR/mount-download-grep."*.txt
test -s "$OUT_DIR/index-script-order."*.txt
grep -Fq "PASS syntax checks" "$OUT_DIR/syntax."*.txt

echo "PASS stage-17k-r13p download snapshot handler inventory read-only smoke"
