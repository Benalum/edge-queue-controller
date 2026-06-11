# Stage 5O-36 Companion Browser Render Regression Smoke

## Purpose

Stage 5O-36 adds a regression smoke for the Stage 5O-35 Companion visual UX redesign.

The normal route smoke confirms the wrapper serves `/companion`, but it does not prove that the browser-loaded JavaScript enhanced the page. This smoke checks the shipped assets and, when browser tooling is available, verifies the rendered Companion UI includes the Stage 5O-35 shell.

## Scope

- Test-only stage.
- No runtime behavior changes.
- No backend route changes.
- No queue behavior changes.
- No auth/header behavior changes.
- No local calendar database.

## What is checked

- `frontend/wrapper-ui/app.js` syntax.
- Stage 5O-35 markers exist in app and CSS.
- `index.html` references cache-busted `app.js` and `styles.css`.
- `/companion` is reachable from the local wrapper.
- The live `app.js` and `styles.css` served by the wrapper contain Stage 5O-35 markers.
- Optional browser-render check if Playwright is available.
