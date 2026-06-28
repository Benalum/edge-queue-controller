#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
python3 "${REPO_ROOT}/ops/smoke/check-stage-17c-anki-discovery-manifest.py"
