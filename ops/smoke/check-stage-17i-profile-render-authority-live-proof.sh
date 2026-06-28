#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17i-profile-render-authority-live-proof.md"

test -f "${DOC}"
grep -Fq "Stage 17I — Profile Render Authority Live Proof" "${DOC}"
grep -Fq "publicProfileFetches: 0" "${DOC}"
grep -Fq "privateProfileFetches: 1" "${DOC}"
grep -Fq "ankiPanelCount: 1" "${DOC}"
grep -Fq "stage17i-profile-render-20260628T194236Z" "${DOC}"
grep -Fq "No backend deploy, DB change, nginx restart, cloudflared restart" "${DOC}"

echo "PASS: Stage 17I live proof doc smoke passed"
