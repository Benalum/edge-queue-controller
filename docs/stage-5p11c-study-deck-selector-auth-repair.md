# Stage 5P-11C Study Deck Selector Auth Repair

Fixes the Study page deck selector so Load decks uses the wrapper's active login token.

Problem:

- The Study deck selector used an older generic token scan.
- The wrapper's canonical login token is stored in authState.token and localStorage edgeStudyToken.
- Load decks could fail to render deck choices even though Study data existed.

Fix:

- Prefer authState.token first.
- Prefer localStorage edgeStudyToken next.
- Keep generic token fallback.
- Keep Start button behavior from Stage 5P-11B.

No backend schema changes.
No Companion test/debug tools.
No voice changes.
