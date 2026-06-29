#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT/docs/stage-17k-z-r3-google-drive-and-companion-two-chat-handoff.md"

test -f "$DOC"

grep -Fq "Google Drive and Companion Two-Chat Handoff" "$DOC"
grep -Fq "AI Platform Control — Stage 17K Study/Profile Cleanup + Companion Study Workflow Handoff" "$DOC"
grep -Fq "AI Platform Control — Google Drive Sync Contract Plan" "$DOC"
grep -Fq "AI Platform Control — Companion Source Adapters and Study Workflow" "$DOC"
grep -Fq "Study no longer shows Anki UI" "$DOC"
grep -Fq "Companion no longer shows Anki debug or local-card panels" "$DOC"
grep -Fq "Profile has a minimal Anki panel" "$DOC"
grep -Fq "Companion should not create, edit, delete, import, export, or remove decks/cards." "$DOC"
grep -Fq "Google Drive sync should get a data contract" "$DOC"
grep -Fq "folder/file layout" "$DOC"
grep -Fq "deck, card, session, stats, and study history schemas" "$DOC"
grep -Fq "apc_local" "$DOC"
grep -Fq "anki_local_browser" "$DOC"
grep -Fq "google_drive_synced" "$DOC"
grep -Fq "runCompanionStudyWorkflow" "$DOC"
grep -Fq "Use Python line-list writers" "$DOC"
grep -Fq "Avoid nested Markdown code fences" "$DOC"
grep -Fq "No source runtime patch, frontend deploy, backend deploy, DB write" "$DOC"

echo "PASS: Stage 17K-Z-R3 two-chat handoff smoke passed"
