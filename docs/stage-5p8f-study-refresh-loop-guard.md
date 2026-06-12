# Stage 5P-8F Study Refresh Loop Guard

Fixes a frontend refresh loop introduced by the Study session status card.

Cause:

- Stage 5P-8A added a MutationObserver.
- The status card updated its own text after loading session status.
- The observer saw that text mutation and triggered another status load.
- That caused a fast repeated refresh/update loop.

Fix:

- The Study status card now auto-loads status only once per rendered card.
- Manual Refresh still works.
- Pause / Resume / Stop controls still refresh after command actions.
- The Study button-state interval is reduced from 2 seconds to 10 seconds.

This is frontend-only.
