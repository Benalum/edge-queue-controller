#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
PRIVATE="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js"
PROFILE="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html"

test -f "${INDEX}"
test -f "${PRIVATE}"
test -f "${PROFILE}"

grep -Fq "stage17j-r3-profile-fragment-cache-20260628" "${INDEX}"
grep -Fq "stage17j-r3-profile-fragment-cache-20260628" "${PRIVATE}"
grep -Fq 'cache: "no-store"' "${PRIVATE}"

grep -Fq "<h1>Your profile</h1>" "${PROFILE}"
grep -Fq "Account information for {{email}}." "${PROFILE}"

for forbidden in \
  "Private profile" \
  "Password reset is now connected through Resend SMTP." \
  "data-private-open-recover" \
  "Future profile preferences will live here."; do
  if grep -Fq "${forbidden}" "${PROFILE}"; then
    echo "FAIL: stale Profile text remains in source fragment: ${forbidden}" >&2
    exit 1
  fi
done

echo "PASS: Stage 17J-R3 Profile fragment cache smoke passed"
