# Stage 5O-26 Complete Public Feature Gates — 2026-06-11

## Result

Completed public logged-out feature gates beyond Study.

## Expected logged-out behavior

- `/study` shows public Study summary.
- `/chat` shows public Chat summary.
- `/companion` shows public Companion summary.
- `/profile` shows public Profile summary.
- `/calendar` shows provider-only Calendar summary.
- `/credits` shows public Credits summary.

## Expected logged-in behavior

Logged-in users continue to see the usable application pages.

## Safety

Admin data preloading should not run for logged-out users.
