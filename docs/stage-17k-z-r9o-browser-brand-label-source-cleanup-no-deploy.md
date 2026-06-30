# Stage 17K-Z-R9O — Browser Brand Label Source Cleanup, No Deploy

## Scope

This checkpoint patches active browser/user-facing source labels from the old AlexHartel / AI Platform branding to Buddies Who Study branding.

Mutation scope:

- Active browser/user-facing source brand labels.
- Repo docs/smoke commit/tag/push.
- No runtime mutation.
- No CT/VM/service restart.
- No backend/frontend deploy.
- No DB write.
- No email send.
- No signup opening.
- No password reset request.

## Current checkpoint

- Previous HEAD: `752410d`
- Previous tag: `controller-stage-17k-z-r9n-one-bounded-forgot-password-request-2026-06-30`

## Product decision

Browser labels should now use:

`Buddies Who Study`

The product domain is:

`buddieswhostudy.com`

## Scan terms

The checkpoint scans for:

- `AlexHartel AI Platform`
- `Alex Hartel AI Platform`
- `AlexHartel`
- `Alex Hartel`
- `Hartel`
- `AI Platform`
- obvious standalone browser-label forms of `Alex`

## Patch policy

The patch intentionally avoids a blind historical rewrite.

It patches active browser/user-facing source files only and does not rewrite:

- historical docs,
- generated smoke evidence,
- handoff records,
- backup snapshots,
- archived source copies.

## Safety smoke

The checkpoint rechecks public posture without deploying:

- `https://buddieswhostudy.com/` remains reachable.
- `POST https://buddieswhostudy.com/api/auth/register` remains HTTP 403 with `closed_beta_signup_disabled`.

## Next safe action

Deploy the source-side browser label patch to website-edge in a separate bounded checkpoint, then verify:

- `<title>` / browser tab label says `Buddies Who Study`,
- visible public UI no longer says `AlexHartel AI Platform`,
- `/api/auth/register` remains blocked.
