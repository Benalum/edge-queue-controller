#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-o-companion-local-anki-status-card-live-proof.md"

test -f "${DOC}"

grep -Fq 'Stage 17K-O — Companion Local Anki Status Card Live Proof' "${DOC}"
grep -Fq '9cd94cd' "${DOC}"
grep -Fq '3cd12e0' "${DOC}"
grep -Fq 'controller-stage-17k-n-companion-local-anki-bridge-source-2026-06-28' "${DOC}"
grep -Fq 'controller-stage-17k-n-companion-local-anki-bridge-live-proof-2026-06-28' "${DOC}"

grep -Fq 'ok: true' "${DOC}"
grep -Fq 'bridgeVersion: stage17kn-companion-local-anki-bridge-source-20260628' "${DOC}"
grep -Fq 'panelPresent: true' "${DOC}"
grep -Fq 'panelTextHasLocalOnlyCopy: true' "${DOC}"
grep -Fq 'panelTextHasPrivacyCopy: false' "${DOC}"
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

grep -Fq 'anki-readonly-session.js?v=stage17kk-anki-basic-memory-session-20260628-r4-status-repair' "${DOC}"
grep -Fq 'companion-local-anki-bridge.js?v=stage17kn-companion-local-anki-bridge-source-20260628' "${DOC}"

grep -Fq 'no question text returned' "${DOC}"
grep -Fq 'no answer text returned' "${DOC}"
grep -Fq 'backend calls disallowed' "${DOC}"
grep -Fq 'model calls disallowed' "${DOC}"
grep -Fq 'Anki writes disallowed' "${DOC}"
grep -Fq 'No frontend deploy, backend deploy, DB write' "${DOC}"

echo "PASS: Stage 17K-O Companion local Anki status card live proof smoke passed"
