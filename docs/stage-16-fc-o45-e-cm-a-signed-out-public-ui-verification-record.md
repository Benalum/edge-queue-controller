# Stage 16 FC-O45-E-CM-A — Signed-Out Public UI Verification Record

Date: 2026-06-26

## Summary

CM-A records CL-Z, the read-only signed-out public UI behavior verification for the Study Companion last-message UI control.

CM-A is docs/smoke only.

No frontend source patch, frontend deploy, public /var/www mutation, backend deploy, CT203 runtime patch, DB write, job mutation, result insert, service mutation, timer/worker activation, model/Ollama/PVESO call, CT/VM restart, or secret printing occurs in CM-A.

## Repo baseline

Repo HEAD/origin/main before CM-A:

    afc576c

Previous record commit:

    docs: record wrapper app deploy cache proof

Previous tag:

    controller-stage-16-fc-o45-e-cl-y-record-wrapper-app-js-deploy-public-cache-proof-2026-06-26

Repo wrapper app SHA:

    c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835

CL-U marker:

    APC_COMPANION_LAST_MESSAGE_CL_U

## Backend and VM200 verification

CL-Z verified active CT203 backend SHA:

    eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30

CL-Z verified VM200 app.js SHA:

    c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835

CL-Z verified VM200 app.js has the CL-U marker.

CL-Z verified VM200 nginx and cloudflared were active.

## Public signed-out UI path

CL-Z verified public root:

    GET / => HTTP 200

Public root referenced:

    /app.js?v=20260624fc045eccmanual2

Public root did not directly contain the CL-U marker, which is expected because the marker lives in app.js.

## Public referenced app.js

CL-Z verified the app.js referenced by public root:

    GET /app.js?v=20260624fc045eccmanual2 => HTTP 200
    bytes=571050
    sha256=c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835

The referenced app.js contains:

    APC_COMPANION_LAST_MESSAGE_CL_U
    apcCompanionLastMessageClU
    Study Companion signed-out copy
    Please sign in to use the Study Companion.
    /api/companion/study/action
    action: "last_message"
    result.status === 401

## Public fresh cache-busted app.js

CL-Z verified:

    GET /app.js?v=20260626clz => HTTP 200
    bytes=571050
    sha256=c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835

## Public API safety

CL-Z verified public health routes:

    GET /api/system/status => HTTP 200
    GET /api/companion/voice/status => HTTP 200

CL-Z verified signed-out API protection:

    POST /api/companion/study/action action=last_message => HTTP 401
    POST /api/companion/study/action action=status => HTTP 401

No deterministic no-model response was exposed to unauthenticated requests.

No backend model label was exposed to unauthenticated requests.

## Conclusion

The signed-out public UI path is verified.

The public page loads a cache-busted app.js URL that serves the deployed CL-U Study Companion last-message UI source.

The UI includes signed-out copy for the Study Companion control.

The backend remains protected for signed-out users.

## Recommended next step

Next stage can be a token-safe authenticated UI proof, only if explicitly approved.

The authenticated proof should preserve the same guardrails used in CL-Q-R3:

    temporary token only
    no token value printed
    no token hash printed
    temporary session revoked
    public authenticated last_message returns HTTP 200
    no job/result/model/timer/worker activation
