#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VENDOR_DIR="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/vendor/sqljs"
DOC="${REPO_ROOT}/docs/stage-17k-d-vendor-sqljs-assets.md"

test -d "${VENDOR_DIR}"
test -f "${VENDOR_DIR}/sql-wasm.js"
test -f "${VENDOR_DIR}/sql-wasm.wasm"
test -f "${VENDOR_DIR}/LICENSE.sql-js"
test -f "${VENDOR_DIR}/VERSION.txt"
test -f "${VENDOR_DIR}/SHA256SUMS"
test -f "${DOC}"

grep -Fq "sql.js version: 1.12.0" "${VENDOR_DIR}/VERSION.txt"
grep -Fq "Do not load sql.js from a CDN in production" "${VENDOR_DIR}/VERSION.txt"
grep -Fq "Stage 17K-D — Vendor sql.js Assets" "${DOC}"
grep -Fq "Do not use a CDN dependency for production" "${DOC}"
grep -Fq "No frontend deploy, backend deploy, DB write" "${DOC}"

if grep -RInE "unpkg|jsdelivr|cdnjs|cdn.jsdelivr|cdnjs.cloudflare" "${VENDOR_DIR}/sql-wasm.js" >/tmp/apc-stage17kd-cdn-grep.txt 2>/dev/null; then
  echo "FAIL: CDN reference found in vendored sql-wasm.js" >&2
  cat /tmp/apc-stage17kd-cdn-grep.txt >&2
  exit 1
fi

(
  cd "${VENDOR_DIR}"
  sha256sum -c SHA256SUMS
)

# sql.js 1.12.0 minified loader is about 49 KB; wasm is about 653 KB.
test "$(wc -c < "${VENDOR_DIR}/sql-wasm.js")" -gt 40000
test "$(wc -c < "${VENDOR_DIR}/sql-wasm.wasm")" -gt 600000

echo "PASS: Stage 17K-D vendored sql.js assets smoke passed"
