#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-q-companion-local-anki-current-card-shape-command-live-proof.md"

test -f "${DOC}"

grep -Fq 'Stage 17K-Q — Companion Local Anki Current Card Shape Command Live Proof' "${DOC}"
grep -Fq 'bbe3c9f' "${DOC}"
grep -Fq 'controller-stage-17k-q-companion-local-anki-card-shape-command-2026-06-28' "${DOC}"
grep -Fq 'stage17kq-companion-local-anki-current-card-shape-command-20260628' "${DOC}"

grep -Fq 'ok: true' "${DOC}"
grep -Fq 'bridgeVersion: stage17kq-companion-local-anki-current-card-shape-command-20260628' "${DOC}"
grep -Fq 'command: current_anki_card_shape' "${DOC}"
grep -Fq 'panelHasButton: true' "${DOC}"
grep -Fq 'panelHasOutput: true' "${DOC}"
grep -Fq 'doesNotReturnQuestionText: true' "${DOC}"
grep -Fq 'doesNotReturnAnswerText: true' "${DOC}"
grep -Fq 'noBackendAllowed: true' "${DOC}"
grep -Fq 'noModelAllowed: true' "${DOC}"
grep -Fq 'noAnkiWriteAllowed: true' "${DOC}"

grep -Fq 'source: anki_browser_local' "${DOC}"
grep -Fq 'status: idle' "${DOC}"
grep -Fq 'cards in memory: 0' "${DOC}"
grep -Fq 'current card shape: none' "${DOC}"
grep -Fq 'Privacy: this command does not return card question text or answer text' "${DOC}"

grep -Fq 'It did not contain a `question` field' "${DOC}"
grep -Fq 'It did not contain an `answer` field' "${DOC}"
grep -Fq 'No backend deploy, DB write, Anki write' "${DOC}"
grep -Fq 'No Anki question text or answer text was saved to repo docs' "${DOC}"

echo "PASS: Stage 17K-Q Companion local Anki current-card-shape command live proof smoke passed"
