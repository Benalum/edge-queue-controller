#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-ch-e-r2-backend-companion-study-action-live-deploy.md"

test -f "$DOC"

grep -Fq "Backend Companion Study Action Live Deploy" "$DOC"
grep -Fq "/opt/edge-queue-controller/current/edge_controller.py" "$DOC"
grep -Fq "008b11765b7e677e13b1053afcf48046b0d411c03080128d7920b32542887088" "$DOC"
grep -Fq "8b6c0681f16e2d26f49c4a555b60e703aafbda63a1ed05c439f3ecdbdcab3e9f" "$DOC"
grep -Fq "stage-16-fc-o45-e-ch-e-r2-backend-companion-study-action-deploy-20260626T032955Z" "$DOC"
grep -Fq "edge-queue-controller.service" "$DOC"
grep -Fq "port 7070" "$DOC"
grep -Fq "/api/companion/study/action" "$DOC"
grep -Fq "/public/companion/study/action" "$DOC"
grep -Fq "Question one" "$DOC"
grep -Fq "Answer one" "$DOC"
grep -Fq "mutated=false" "$DOC"
grep -Fq "No frontend patch" "$DOC"

echo "PASS stage-16-fc-o45-e-ch-f backend deploy record smoke"
