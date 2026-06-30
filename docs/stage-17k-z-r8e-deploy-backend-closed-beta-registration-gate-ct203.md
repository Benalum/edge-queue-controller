# Stage 17K-Z-R8E — Deploy Backend Closed Beta Registration Gate to CT203

Status: live CT203 backend deploy complete  
Baseline source: `9cc8c46`

## Purpose

Deploy the R8D backend closed-beta registration gate to the live CT203 controller.

## Live target

- CT: `203`
- Live file: `/opt/edge-queue-controller/releases/head-a39021f/edge_controller.py`
- Service: `edge-queue-controller.service`

## Live result

The targeted CT203 deploy/restart completed successfully.

Observed deploy marker:

`PASS_CT203_R8E_TARGETED_DEPLOY_RESTART`

Observed post-deploy verification:

- `/api/auth/register` returned HTTP `403`
- response included `closed_beta_signup_disabled`
- response included `Buddies Who Study`
- response included the closed-beta account-creation message
- `/api/auth/login` remained POST-capable
- `/api/me` remained GET-capable
- CT203 controller service remained active
- `/system/status` remained reachable locally on CT203

## Deployed behavior

Public account creation is closed while Buddies Who Study is prepared for beta.

Registration/create-account endpoints return:

- HTTP `403`
- code `closed_beta_signup_disabled`
- message: `Beta testing is not open yet. Account creation is temporarily closed while we prepare Buddies Who Study.`

Existing sign-in routes remain present.

## Boundaries Held

R8E did not:

- mutate VM200 static files;
- mutate DNS or Cloudflare;
- mutate Google Cloud;
- mutate email provider settings;
- manually write DB rows;
- intentionally send email;
- call models;
- activate workers or schedulers.

## Note

The first R8E verifier used `curl -f`, which correctly saw HTTP `403` but did not save the response body because `curl -f` treats 4xx responses as failures. R8E finalization re-ran the live verification without `-f` and confirmed the response body.
