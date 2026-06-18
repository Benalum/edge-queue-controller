#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-jn-pvew-contained-platform-pivot-no-apply.md"

echo "=== smoke: Phase 14J-JN PVEW-contained platform pivot, no apply ==="

test -f "$DOC"

grep -F "MUTATION_SCOPE: docs_smoke_only_no_apply" "$DOC"
grep -F "Get the website/platform working from containers" "$DOC"
grep -F "Do not keep the laptop in the live authority path" "$DOC"
grep -F "Use the laptop later only as an optional worker" "$DOC"
grep -F "previously prepared CT204 read-only bind-mount apply should not be run yet" "$DOC"
grep -F "PVEW target role" "$DOC"
grep -F "CT203: private controller/API/queue candidate" "$DOC"
grep -F "CT204: private data/backups candidate" "$DOC"
grep -F "Laptop: not live authority" "$DOC"
grep -F "Fast-lane objective" "$DOC"
grep -F "Phase 14J-JO - PVEW-contained website recovery baseline, read-only" "$DOC"
grep -F "Separate explicit approval is required" "$DOC"

echo "PASS: Phase 14J-JN PVEW-contained platform pivot doc validated"
