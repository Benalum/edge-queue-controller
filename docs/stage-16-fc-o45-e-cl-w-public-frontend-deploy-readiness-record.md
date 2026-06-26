# Stage 16 FC-O45-E-CL-W — Public Frontend Deploy Readiness Record

Date: 2026-06-26

## Summary

CL-W records the CL-V read-only public frontend deploy readiness inventory for the wrapper Study Companion last-message UI control.

CL-V did not mutate files, patch source, deploy frontend assets, mutate public /var/www, deploy backend runtime, write DB rows, start services, activate timers/workers, call models, or restart CTs/VMs.

## Repo baseline

Repo HEAD/origin/main before CL-W:

    7e9911d

CL-U-R2 source-only UI patch commit:

    feat: add wrapper companion last message control

CL-U-R2 tag:

    controller-stage-16-fc-o45-e-cl-u-r2-wrapper-ui-last-message-control-source-only-2026-06-26

Repo wrapper app source SHA from CL-V:

    c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835

CL-U marker present in repo source:

    APC_COMPANION_LAST_MESSAGE_CL_U

## Backend baseline

Live CT203 backend SHA verified during CL-V:

    eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30

The auth-gated last_message backend remained present.

Public unauthenticated last_message remained protected:

    POST /api/companion/study/action action=last_message => HTTP 401 Missing bearer token

Public health checks remained healthy:

    GET /api/system/status => HTTP 200
    GET /api/companion/voice/status => HTTP 200

## VM200 live frontend inventory

CL-V found the live wrapper static app path:

    /var/www/apc-wrapper-local/app.js

Live app.js properties:

    bytes=547265
    sha256=260756d06884743c4dbc3227e4e35920301d1411f1ec5ff681dedb63a1706f08
    has CL-U marker=no
    has Study auth cleanup marker=yes

VM200 local HTTP served the same app.js content for:

    /app.js
    /app.js?v=20260626clv

Both returned:

    HTTP 200
    bytes=547265
    sha256=260756d06884743c4dbc3227e4e35920301d1411f1ec5ff681dedb63a1706f08
    CL-U marker=no

## VM200 live index inventory

CL-V found the live wrapper index path:

    /var/www/apc-wrapper-local/index.html

Live index properties:

    bytes=4800
    sha256=0a22952302d2973c6911f7b051a695df7848e7c422d3aa4c08d51a9882cddfed

Current script reference:

    /app.js?v=20260624fc045eccmanual2

## API bridge inventory

CL-V saw active nginx bridge snippets routing controller APIs to CT203 via:

    192.168.0.250:7070

Relevant public API behavior stayed correct:

    /api/system/status => CT203 system status
    /api/companion/voice/status => CT203 voice status
    /api/companion/study/action => CT203 companion study action

## Safe future deploy target

The safe frontend deploy target for CL-X is:

    /var/www/apc-wrapper-local/app.js

The deploy should:

1. Create a timestamped backup directory under /var/www/apc-wrapper-local.
2. Backup current app.js.
3. Verify backup SHA equals the current live SHA:
       260756d06884743c4dbc3227e4e35920301d1411f1ec5ff681dedb63a1706f08
4. Copy repo frontend/wrapper-ui/app.js to /var/www/apc-wrapper-local/app.js.
5. Verify new live SHA equals repo wrapper app SHA:
       c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835
6. Do not restart nginx or cloudflared unless a read-only smoke proves it is required.
7. Smoke /app.js and a cache-busted /app.js URL.
8. Verify the CL-U marker appears after deploy.
9. Verify public unauthenticated last_message remains HTTP 401.
10. Verify no backend, DB, job, result, model, timer, worker, CT, or VM mutation occurs.

## Index cache-bust decision

CL-V showed that cache-busted URLs already serve the same app.js content:

    /app.js
    /app.js?v=20260626clv

Therefore CL-X can deploy app.js first without mutating index.html.

If browser cache behavior remains stale later, index.html cache-bust mutation can be handled in a separate approved step.

## Recommendation

Next stage should be CL-X:

    deploy frontend/wrapper-ui/app.js to VM200 /var/www/apc-wrapper-local/app.js only
    create backup first
    no index.html mutation
    no nginx/cloudflared restart
    public smoke with /app.js and /app.js?v=20260626clx
    verify CL-U marker is present
    verify unauth last_message still returns HTTP 401
    verify repo remains clean
