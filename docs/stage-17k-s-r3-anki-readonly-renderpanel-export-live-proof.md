# Stage 17K-S-R3 — Anki Readonly renderPanel Export Live Proof

Date: 2026-06-28

Stage 17K-S-R3 live proof passed.

- Source commit: `a859316`
- Source tag: `controller-stage-17k-s-r3-anki-readonly-renderpanel-export-2026-06-28`
- VM200 backup: `/home/jkg76nid/apc-vm200-frontend-backups/stage17ks-r3-anki-readonly-renderpanel-export-20260628T234224Z`

Live markers:
- Bridge: `stage17ks-r2-companion-local-anki-session-mount-output-repair-20260628`
- Anki adapter: `stage17ks-r3-anki-readonly-renderpanel-export-20260628`

Browser proof:
- `ok: true`
- `bridgeVersion: stage17ks-r2-companion-local-anki-session-mount-output-repair-20260628`
- `ankiAdapterVersion: stage17ks-r3-anki-readonly-renderpanel-export-20260628`
- `adapterHasRenderPanel: true`
- `command: mount_anki_session_adapter`
- `mounted: true`
- `panelHasMountButton: true`
- `panelHasMountOutput: true`
- `doesNotReturnQuestionText: true`
- `doesNotReturnAnswerText: true`
- `noBackendAllowed: true`
- `noModelAllowed: true`
- `noAnkiWriteAllowed: true`

Message proof:
- `adapter present: yes`
- `adapter rendered: yes`
- `source: anki_browser_local`
- `status: idle`
- `active: no`
- `deck: Anki Deck2`
- `cards in memory: 0`
- `reviewed: 0`
- `correct / wrong: 0 / 0`

`mounted: true` closes the Stage 17K-S adapter mount repair.

The Companion bridge can now call the Anki read-only adapter renderPanel API.

The command returns only status and aggregate session information.

It does not return Anki question text or answer text.

It does not allow backend calls, model calls, Anki writes, or MyDecks writeback.

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation was performed for this proof.

No Anki question text or answer text was saved to repo docs.
