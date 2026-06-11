# Project Cleanup Audit — 2026-06-10

## Working state

- Study page loads without `/login?next=...` redirect.
- Study page renders recovered deck data for active user 16.
- Public gateway service is no longer required in the live path.
- Direct `/api/study/*` and `/api/companion/*` aliases exist in `edge_controller.py`.
- Wrapper handles cookie-backed auth for Study API calls.

## Known remaining cleanup decisions

1. Decide whether deleted `cloudflare/edge-public-proxy/*` files should stay deleted or be restored.
2. Decide whether `public_gateway.py` should remain as archived compatibility code, be deleted, or be moved under `.cleanup-archive`.
3. Decide whether Study standalone header should remain temporarily or be migrated into the shared wrapper layout later.
4. Keep `.cleanup-archive/` out of commits unless intentionally preserving backups.
5. Keep `edge_queue.sqlite3` DB recovery as runtime state, not a source-code migration, unless we add a formal migration script later.

## Do not add new features yet

PDF import / AI flashcard generation should wait until this cleanup is committed and tagged.
