# Stage 17K-Z-R8J-R6 — Final Route Correction, No Mutation

Status: route authority summary finalized from saved R8J-R2 evidence  
Baseline: `99b02aa`

## Purpose

Finalize the route-authority record after failed R8J-R3/R8J-R4/R8J-R5 correction attempts.

R8J-R6 does not rerun public DNS or HTTP checks. It corrects the generated summary from the saved R8J-R2 evidence.

## Correct Finding

`alexhartel.com`:

- resolves through Cloudflare;
- serves the closed-beta app;
- backend `/api/auth/register` returns HTTP `403` with `closed_beta_signup_disabled`.

`buddieswhostudy.com`:

- has Cloudflare nameservers;
- is not publicly routed to the app;
- public HTTP did not resolve during R8J-R2;
- registration endpoint was unreachable with `register_http=000`.

`www.buddieswhostudy.com`:

- is not publicly routed to the app;
- public HTTP did not resolve during R8J-R2;
- registration endpoint was unreachable with `register_http=000`.

VM200 and PVEW SSH timed out during R8J-R2, so host-side route config was not confirmed.

## Corrected Conclusion

The product domain is not yet publicly routed to the closed-beta app.

The next practical step is a manual Cloudflare/dashboard route addition after recording rollback/current values.

## Recommended R8K Manual Dashboard Action

In Cloudflare, route both names to the same closed-beta app route currently serving `alexhartel.com`:

1. `buddieswhostudy.com`
2. `www.buddieswhostudy.com`

Then run public smoke to verify:

- apex loads the closed-beta banner;
- www loads the closed-beta banner;
- header Login/Register opens login;
- register/create-account remains unavailable;
- `/api/auth/register` returns `403 closed_beta_signup_disabled`;
- `/api/me` remains GET-capable;
- `/api/auth/login` remains POST-capable.

## Boundaries Held

R8J-R6 does not mutate DNS, Cloudflare, tunnel routing, Google Cloud, email provider settings, VM200, CT203, backend, DB, nginx/cloudflared, models, workers, or schedulers.
