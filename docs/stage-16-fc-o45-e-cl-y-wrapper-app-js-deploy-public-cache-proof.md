# Stage 16 FC-O45-E-CL-Y — Wrapper App.js Deploy and Public Cache Proof

Date: 2026-06-26

## Summary

CL-Y records the VM200 wrapper app.js deployment and public cache-bust proof for the Study Companion last-message UI control.

This is a docs/smoke record only.

CL-Y does not patch frontend source, deploy frontend assets, mutate public /var/www, patch or deploy backend runtime, write DB rows, mutate jobs/results, start services, activate timers/workers, call models, or restart CTs/VMs.

## Repo baseline

Repo HEAD/origin/main before CL-Y:

    81e1bbd

CL-U-R2 source-only UI patch commit:

    7e9911d

CL-W readiness record commit:

    81e1bbd

Repo wrapper source path:

    frontend/wrapper-ui/app.js

Repo wrapper app SHA:

    c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835

CL-U marker:

    APC_COMPANION_LAST_MESSAGE_CL_U

## Backend baseline

Live CT203 backend SHA:

    eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30

Backend route:

    POST /api/companion/study/action

Protected unauthenticated behavior:

    action=last_message => HTTP 401 Missing bearer token

## CL-X and CL-X-R2 results

CL-X timed out before visible backup or replacement.

CL-X-R0 confirmed CL-X did not deploy.

CL-X-R2 created and verified a VM200 backup but timed out during guest-agent base64 chunk staging.

CL-X-R2-R0 confirmed CL-X-R2 did not deploy app.js and that the backup-only partial state was safe.

CL-X-R2 backup directory:

    /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-stage-16-fc-o45-e-cl-x-r2-wrapper-app-js-deploy-20260626T162939Z

CL-X-R2 backup app SHA:

    260756d06884743c4dbc3227e4e35920301d1411f1ec5ff681dedb63a1706f08

## CL-X-R3 deployment result

CL-X-R3 used a short-lived PVEW HTTP server for VM200 to pull the staged app.js.

Transfer host observed:

    http://100.127.73.75:18765

The temporary PVEW HTTP server was stopped.

The VM200 temp staged app file was removed.

No nginx restart occurred.

No cloudflared restart occurred.

No index.html mutation occurred.

No backend, DB, job, result, model, worker, timer, CT, or VM mutation occurred.

CL-X-R3 backup directory:

    /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-stage-16-fc-o45-e-cl-x-r3-wrapper-app-js-deploy-20260626T163536Z

CL-X-R3 backup app SHA:

    260756d06884743c4dbc3227e4e35920301d1411f1ec5ff681dedb63a1706f08

CL-X-R3 live VM200 app.js after deploy:

    path=/var/www/apc-wrapper-local/app.js
    bytes=571050
    sha256=c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835
    CL-U marker present=yes
    Study auth cleanup marker present=yes

CL-X-R3 live VM200 index.html stayed unchanged:

    path=/var/www/apc-wrapper-local/index.html
    sha256=0a22952302d2973c6911f7b051a695df7848e7c422d3aa4c08d51a9882cddfed

VM200 local smokes after deploy returned new app SHA for:

    /app.js
    /app.js?v=20260626clxr3
    /app.js?v=20260626clxr3r0
    /app.js?v=20260626clxr3r1

## CL-X-R3-R0 verification

CL-X-R3-R0 timed out during public smoke, but verified the VM200 local deploy.

VM200 local app.js:

    sha256=c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835
    bytes=571050
    CL-U marker present=yes
    Study auth cleanup marker present=yes

VM200 local index.html:

    sha256=0a22952302d2973c6911f7b051a695df7848e7c422d3aa4c08d51a9882cddfed
    unchanged=yes

VM200 local app.js routes returned new SHA:

    /app.js
    /app.js?v=20260626clxr3r0

## CL-X-R3-R1 public cache-bust proof

CL-X-R3-R1 completed successfully as a read-only public cache-bust diagnosis.

Public root:

    GET / => HTTP 200
    root references /app.js?v=20260624fc045eccmanual2
    root does not directly contain the CL-U marker

Public direct app.js:

    GET /app.js => HTTP 200
    bytes=547265
    sha256=260756d06884743c4dbc3227e4e35920301d1411f1ec5ff681dedb63a1706f08
    CL-U marker present=no
    cf-cache-status=HIT
    age=1183
    cache-control=max-age=14400

This confirms the direct /app.js URL was stale in Cloudflare cache.

Public current index app.js URL:

    GET /app.js?v=20260624fc045eccmanual2 => HTTP 200
    bytes=571050
    sha256=c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835
    CL-U marker present=yes
    Study Companion signed-in copy present=yes
    cf-cache-status=EXPIRED

Public fresh cache-busted app.js URL:

    GET /app.js?v=20260626clxr3r1 => HTTP 200
    bytes=571050
    sha256=c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835
    CL-U marker present=yes
    Study Companion signed-in copy present=yes
    cf-cache-status=MISS

Public API safety remained correct:

    GET /api/system/status => HTTP 200
    GET /api/companion/voice/status => HTTP 200
    POST /api/companion/study/action action=last_message without bearer => HTTP 401

No deterministic no-model response was exposed to unauthenticated public requests.

## Conclusion

The VM200 app.js deploy is complete.

The public page already references a cache-busted app.js URL:

    /app.js?v=20260624fc045eccmanual2

That URL now serves the new app.js containing the CL-U marker and Study Companion signed-in copy.

Therefore no index.html mutation is required immediately.

The direct /app.js URL remains stale only due to Cloudflare cache HIT and does not block normal public page loads because the root page uses the query-string app.js URL.

## Recommended next step

Next stage should be CL-Z read-only signed-out public UI behavior verification.

It should verify:

    public root HTTP 200
    public root references /app.js?v=20260624fc045eccmanual2
    public current index app.js URL contains APC_COMPANION_LAST_MESSAGE_CL_U
    public unauthenticated last_message remains HTTP 401
    no backend/model/job/timer/worker activation occurs

A later authenticated UI proof can use the existing token-safe temporary session pattern only if explicitly approved.
