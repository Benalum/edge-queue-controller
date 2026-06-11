# Stage 5K-1 Study Shared-Wrapper Layout Audit — 2026-06-10

## Purpose

Audit how to move the working Study dashboard into the shared wrapper layout without breaking Study data, auth, or review behavior.

## Current state

- Study currently works at `/study`.
- Study still serves `frontend/study-ui/index.html`, which has its own standalone header/nav.
- The wrapper shell works for `/`, `/chat`, `/companion`, `/calendar`, `/profile`, `/admin`, and `/system`.
- Study API data is already laptop-controller owned through `/api/study/*`.

## Desired direction

Move Study content into the shared wrapper shell so `/study` uses the same header/nav/account/status layout as the rest of the site.

## Safe migration rule

Do not rewrite Study behavior and layout in one step.

Preferred migration sequence:

1. Extract Study dashboard body into a reusable partial/container.
2. Keep Study JS and Study CSS working as-is.
3. Serve `/study` through wrapper shell with Study assets loaded only on Study route.
4. Smoke-test recovered deck display.
5. Only then remove the standalone Study header/nav.

## Must preserve

- No `/login?next=...` redirect.
- Recovered deck remains visible.
- Expected Study state: 1 active deck, 4 cards, 6 reviews, 50% accuracy.
