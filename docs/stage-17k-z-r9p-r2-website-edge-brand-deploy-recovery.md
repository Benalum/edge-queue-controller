# Stage 17K-Z-R9P-R2 — Website Edge Brand Deploy Recovery

## Scope

This checkpoint recovers from the failed R9P deploy attempt.

Allowed mutation:

- Attempt direct no-sudo VM200 static webroot deploy if writable.
- Otherwise record a clean blocker and leave a ready package on VM200.
- Repo docs/smoke commit/tag/push.

Explicitly not allowed:

- No backend deploy.
- No CT203 mutation.
- No DB write.
- No email send.
- No signup opening.
- No password reset request.
- No nginx/cloudflared config mutation.
- No service restart/reload/start/stop.
- No CT/VM restart.

## Prior failure

R9P built and uploaded the correct static package, but deploy did not occur because `jkg76nid` cannot use passwordless sudo on `website-edge`.

Public title remained:

`AlexHartel AI Platform`

## R9P-R2 behavior

R9P-R2 tries direct no-sudo static deployment only if `/var/www/apc-wrapper-local` is writable by `jkg76nid`.

If direct deployment is not writable, it records:

- the blocker,
- the uploaded package path,
- the manual interactive sudo deployment command.

## Desired public result

After deployment, public root should show:

`Buddies Who Study`

and `/api/auth/register` should remain HTTP 403 with:

`closed_beta_signup_disabled`
