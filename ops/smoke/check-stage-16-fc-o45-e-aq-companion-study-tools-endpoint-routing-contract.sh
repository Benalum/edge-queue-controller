#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-aq-companion-study-tools-endpoint-routing-contract.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AQ" "$DOC"
grep -Fq "Companion to Study Tools Endpoint Routing Contract" "$DOC"
grep -Fq "normal browser signed-in submit" "$DOC"
grep -Fq "queue worker reads that job" "$DOC"
grep -Fq "Study session start" "$DOC"
grep -Fq "Study session pause" "$DOC"
grep -Fq "Study session resume" "$DOC"
grep -Fq "Study session stop" "$DOC"
grep -Fq "Read the answer" "$DOC"
grep -Fq "study_card_correct" "$DOC"
grep -Fq "study_card_wrong" "$DOC"
grep -Fq "study_card_skip" "$DOC"
grep -Fq "APPROVE_FC_O45_E_AS_EXACT_ONE_COMPANION_STUDY_SESSION_START" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO model generation" "$DOC"
grep -Fq "Source inventory" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AQ Companion Study Tools endpoint routing contract doc smoke"
