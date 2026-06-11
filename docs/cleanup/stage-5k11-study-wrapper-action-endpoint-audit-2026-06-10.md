# Stage 5K-11 Study Wrapper Action Endpoint Audit — 2026-06-10

## Purpose

Audit the existing standalone Study action payloads and backend routes before wiring create/review actions into /study-wrapper-preview.

## Why

/study-wrapper-preview is currently accurate and read-only. Before making it interactive, the wrapper route must match the existing Study API payloads exactly.

## Current safe state

- /study-wrapper-preview uses shared wrapper layout.
- /study-wrapper-preview hydrates Study counts, deck summary, buckets, and card stats.
- /study-wrapper-preview is read-only.
- /study remains the live interactive Study page.

## Next safe implementation order

1. Wire deck select switching in preview.
2. Wire create deck.
3. Wire add card.
4. Wire load review queue.
5. Wire show answer / correct / wrong / skip review actions.
6. Only after all smoke tests pass, decide whether /study-wrapper-preview can replace /study.
