#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cl-e-authenticated-companion-study-last-message-mvp-plan.md"

test -f "$DOC"

check() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

check "Authenticated Companion/Study Last-Message MVP Plan"
check "HEAD/origin/main=bdc0845"
check "queued_companion=0"
check "cleanup_rows=440"
check "cleanup_tool_candidate_count=0"
check "CK-Y job581 completed exact marker"
check "1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2"
check "16d5e145ee3fc917ff8474f82dac4c91ce4d6397c4cea54c0f1b4f3bc560af6f"
check "POST /api/companion/study/action"
check "action=last_message"
check "authenticated=true"
check "HTTP 401"
check "Missing bearer token"
check "backend-deterministic/no-model"
check "Option A — direct deterministic response"
check "Option B — bounded deterministic queue job"
check "CL-F — source-only backend contract patch"
check "CL-G — deploy backend contract to CT203"
check "CL-H — authenticated local/controlled proof"
check "no model/Ollama/PVESO call"
check "no scheduler/timer/persistent-worker activation"
check "queued_any=25"
check "running_any=10"
check "Do not activate broad queue dispatch"
check "direct deterministic response first"

echo "PASS stage-16-fc-o45-e-cl-e authenticated companion study MVP plan smoke"
