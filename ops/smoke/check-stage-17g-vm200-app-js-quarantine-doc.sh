#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17g-vm200-app-js-quarantine.md"

test -f "${DOC}"
grep -Fq "Stage 17G — VM200 app.js Quarantine" "${DOC}"
grep -Fq "app.js.disabled-20260628T193103Z" "${DOC}"
grep -Fq "backups/app-js-quarantine-20260628T193103Z/app.js" "${DOC}"
grep -Fq "No backend deploy, DB change, nginx restart, cloudflared restart" "${DOC}"

echo "PASS: Stage 17G VM200 app.js quarantine doc smoke passed"
