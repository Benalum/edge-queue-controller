# Stage 17K-Z-R8D — Backend Closed Beta Registration Gate Source

Status: source-only backend patch  
Baseline: `e73453a`

## Purpose

Block backend public account creation before migrating the product to `buddieswhostudy.com`.

The frontend closed-beta gate from R8B is not enough because users can still call backend registration endpoints directly. R8D adds the backend source gate.

## User-facing refusal

`Beta testing is not open yet. Account creation is temporarily closed while we prepare Buddies Who Study.`

## Source file

`edge_controller.py`

## Gated routes

- `/public/auth/register`
- `/api/auth/register`
- `/system/session/register`

## Preserved routes

Existing/test user sign-in must remain available:

- `/public/auth/login`
- `/api/auth/login`

Verification/resend routes are not the account-creation entrypoint and are preserved for existing pending flows unless a later beta policy chooses otherwise.

## Behavior

Registration/create-account endpoints must return:

- HTTP status: `403`
- code: `closed_beta_signup_disabled`
- message: `Beta testing is not open yet. Account creation is temporarily closed while we prepare Buddies Who Study.`

## Not Performed

R8D does not:

- deploy to CT203;
- write live CT203 files;
- restart backend;
- write DB rows;
- POST registration data;
- send email;
- mutate DNS/Cloudflare;
- mutate Google Cloud;
- mutate email provider settings;
- deploy VM200 static files.

## Next

R8E should deploy the backend source to CT203/controller and restart only the controller service if needed, then verify:

- live `/api/auth/register` refuses with `403 closed_beta_signup_disabled`;
- live login route remains present;
- no account is created;
- no verification email is sent.
