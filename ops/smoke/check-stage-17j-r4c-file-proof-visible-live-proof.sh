#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17j-r4c-file-proof-visible-live-proof.md"

test -f "${DOC}"
grep -Fq "Stage 17J-R4C — Anki File Picker Only Live Proof" "${DOC}"
grep -Fq "b51b6e7" "${DOC}"
grep -Fq "stage17j-r4c-file-proof-visible-20260628" "${DOC}"
grep -Fq "detailsOpen: true" "${DOC}"
grep -Fq "hasFileProof: true" "${DOC}"
grep -Fq "hasOldManifestTitle: false" "${DOC}"
grep -Fq "hasOldProfiles: false" "${DOC}"
grep -Fq "hasPasteManifest: false" "${DOC}"
grep -Fq "No backend deploy, DB change, nginx restart, cloudflared restart" "${DOC}"

echo "PASS: Stage 17J-R4C live proof doc smoke passed"
