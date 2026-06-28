#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17j-r3-profile-fragment-cache-live-proof.md"

test -f "${DOC}"
grep -Fq "Stage 17J-R3 — Profile Fragment Cache Live Proof" "${DOC}"
grep -Fq "c22343b" "${DOC}"
grep -Fq "hasPrivateProfile: false" "${DOC}"
grep -Fq "hasPassword: false" "${DOC}"
grep -Fq "hasPreferencesPlaceholder: false" "${DOC}"
grep -Fq "detailsOpenInitial: false" "${DOC}"
grep -Fq "stage17j-r3-profile-fragment-cache-20260628T200027Z" "${DOC}"
grep -Fq "No backend deploy, DB change, nginx restart, cloudflared restart" "${DOC}"

echo "PASS: Stage 17J-R3 live proof doc smoke passed"
