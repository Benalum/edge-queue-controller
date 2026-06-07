#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

DOC="docs/chatgpt-terminal-bridge-workflow.md"

if [ ! -f "$DOC" ]; then
  echo "FAIL: missing $DOC"
  exit 1
fi

required_markers=(
  "ChatGPT Terminal Bridge Workflow"
  "Exact operator checklist"
  "cgpt-workflow phase"
  "cgpt-apply"
  "cgpt-output"
  "Do not run \`cgpt-apply\` immediately after \`cgpt-workflow phase\`"
  "Do not type \`RUN\` directly into your terminal"
  "Do not type \`cgpt-output\` inside the \`cgpt-apply\` prompt"
)

for marker in "${required_markers[@]}"; do
  if ! grep -Fq "$marker" "$DOC"; then
    echo "FAIL: missing marker in $DOC: $marker"
    exit 1
  fi
done

echo "PASS: ChatGPT bridge workflow doc has required operator safety markers"
