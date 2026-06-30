# Stage 17K-Z-R8G-R7 — Browser Validation and Failed R6 Local Cleanup

Status: browser validation recorded; failed local R6 patch cleaned  
Baseline: `94fbd30`

## Purpose

Record that the live header Login/Register behavior is now acceptable after R8G-R4, and clean up the failed local R8G-R6/R8G-R6-R2/R8G-R6-R3 partial `index.html` change.

## Browser Observation

User confirmed:

- clicking **Login / Register** in the header opens the auth modal;
- the modal shows **Login** and **Forgot password**;
- registration/create-account is not shown.

This is the desired closed-beta posture.

## Live Validation

Live HTTP checks confirmed:

- public banner says exactly: `Beta testing is not open yet. Account creation is temporarily closed while we prepare Buddies Who Study.`
- old Anki/Companion/Google sync banner tail is not present;
- `#authModal` exists;
- `#loginTabBtn` exists;
- `#registerTabBtn` exists but is disabled/hidden;
- closed-beta signup guard remains loaded;
- backend `/api/auth/register` returns HTTP `403` with `closed_beta_signup_disabled`.

## Cleanup

The failed R8G-R6 attempts were not deployed or committed, but left a local dirty `index.html`. R8G-R7 restored only that failed local `index.html` change before recording this validation.

## Boundaries Held

R8G-R7 did not:

- deploy frontend files;
- deploy backend code;
- write VM200 files;
- write CT203 files;
- restart backend;
- write DB rows;
- mutate DNS/Cloudflare;
- mutate Google Cloud;
- mutate email provider settings;
- restart nginx/cloudflared;
- call models;
- activate workers or schedulers.

## Current Posture

Closed-beta posture is good:

- existing login is usable;
- account creation is not available in the UI;
- backend registration remains blocked.
