#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-p-companion-local-anki-visible-privacy-copy-live-proof.md"

test -f "${DOC}"

grep -Fq 'Stage 17K-P — Companion Local Anki Visible Privacy Copy Live Proof' "${DOC}"
grep -Fq 'd3c0fb4' "${DOC}"
grep -Fq 'controller-stage-17k-p-companion-local-anki-visible-privacy-copy-2026-06-28' "${DOC}"
grep -Fq 'stage17kp-companion-local-anki-visible-privacy-copy-20260628' "${DOC}"
grep -Fq 'stage17kp-companion-local-anki-visible-privacy-copy-20260628T225750Z' "${DOC}"

grep -Fq 'ok: true' "${DOC}"
grep -Fq 'bridgeVersion: stage17kp-companion-local-anki-visible-privacy-copy-20260628' "${DOC}"
grep -Fq 'panelPresent: true' "${DOC}"
grep -Fq 'panelTextHasLocalOnlyCopy: true' "${DOC}"
grep -Fq 'panelTextHasPrivacyCopy: true' "${DOC}"
grep -Fq 'state.bridge_ready: true' "${DOC}"
grep -Fq 'state.anki_adapter_present: true' "${DOC}"
grep -Fq 'state.source_type: anki_browser_local' "${DOC}"
grep -Fq 'state.status: idle' "${DOC}"
grep -Fq 'state.active: false' "${DOC}"

grep -Fq 'doesNotReturnQuestionText: true' "${DOC}"
grep -Fq 'doesNotReturnAnswerText: true' "${DOC}"
grep -Fq 'noBackendAllowed: true' "${DOC}"
grep -Fq 'noModelAllowed: true' "${DOC}"
grep -Fq 'noAnkiWriteAllowed: true' "${DOC}"

grep -Fq 'This bridge does not return card question text or answer text.' "${DOC}"
grep -Fq 'It does not return Anki question text' "${DOC}"
grep -Fq 'It does not return Anki answer text' "${DOC}"
grep -Fq 'It does not allow backend calls' "${DOC}"
grep -Fq 'It does not allow model calls' "${DOC}"
grep -Fq 'It does not allow Anki writes' "${DOC}"
grep -Fq 'No backend deploy, DB write, Anki write' "${DOC}"

echo "PASS: Stage 17K-P Companion local Anki visible privacy copy live proof smoke passed"
