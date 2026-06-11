# Stage 5K-19 Study Shared Wrapper Controlled Cutover — 2026-06-10

## Result

Cut over exact /study to the shared wrapper Study implementation.

## Route behavior after cutover

- /study serves the shared wrapper shell.
- /study-wrapper-preview remains available as the candidate/preview route.
- /study-standalone serves the old standalone Study page as a temporary fallback.
- /study/* still serves Study assets and partials such as /study/styles.css and /study/study-dashboard.partial.html.

## Study functionality now available through shared wrapper /study

- progress hydration
- deck list and selected deck summary
- card stats and difficulty buckets
- deck select switching
- create deck
- add card
- load review queue
- show answer
- skip card
- correct/wrong review submit

## Data safety

The recovered Study deck remains active:

- Recovered - Math 316 Review
- 4 cards
- 6 reviews

## Fallback

Use /study-standalone#study to access the old standalone Study page during cutover verification.
