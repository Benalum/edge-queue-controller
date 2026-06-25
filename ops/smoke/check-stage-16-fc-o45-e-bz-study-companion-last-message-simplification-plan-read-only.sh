#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bz-study-companion-last-message-simplification-plan-read-only.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O45-E-BZ" "$DOC"
grep -Fq "Study Companion Last-Message" "$DOC"
grep -Fq "SHIFT_TO_STUDY_COMPANION_LAST_MESSAGE_MVP" "$DOC"
grep -Fq "FC-O45-E-CA" "$DOC"
grep -Fq "FC-O45-E-CB" "$DOC"
grep -Fq "FC-O45-E-CC" "$DOC"
grep -Fq "NO source patch" "$DOC"
grep -Fq "NO live deploy" "$DOC"
grep -Fq "NO public" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO job mutation" "$DOC"
grep -Fq "NO model/helper/Ollama call" "$DOC"
grep -Fq "NO scheduler activation" "$DOC"
grep -Fq "NO persistent worker activation" "$DOC"

echo "PASS: Stage 16 FC-O45-E-BZ Study Companion last-message simplification plan read-only smoke"
