# Stage 16 FC-O45-E-CL-T — Frontend/Public UI Inventory for Last-Message Control

Date: 2026-06-26

## Summary

CL-T records the CL-S read-only frontend/public inventory for adding a minimal authenticated Study Companion last-message control.

CL-S did not mutate files, deploy frontend assets, patch public /var/www, patch backend runtime, write DB rows, start services, activate timers/workers, or call models.

## Baseline

Repo HEAD/origin/main before CL-T:

    80c57f1

Live CT203 active backend SHA verified during CL-S:

    eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30

Backend auth-gated last-message source was present.

Public unauthenticated last_message remained protected:

    POST /api/companion/study/action action=last_message => HTTP 401 Missing bearer token

Public status routes remained healthy:

    GET /api/system/status => HTTP 200
    GET /api/companion/voice/status => HTTP 200

## Candidate UI files

CL-S found these useful frontend/source candidates:

    frontend/wrapper-ui/app.js
    frontend/wrapper-ui/dev_server.py
    frontend/study-ui/study-dashboard.partial.html
    frontend/study-ui/styles.css

## Best patch target

The safest first source-only UI target is:

    frontend/wrapper-ui/app.js

Reason:

1. It already mounts dynamic Study tools into the wrapper UI.
2. It already uses authenticated API helper patterns.
3. It already handles signed-out cleanup by removing the Study tools panel when protected Study endpoints return unauthorized.
4. It is closer to the currently deployed wrapper shell behavior than the standalone Study partial.
5. It can add a small minimal control without changing backend auth or public routing.

## Existing wrapper app patterns

CL-S found an existing dynamic Study tools panel in `frontend/wrapper-ui/app.js`.

Useful markers/patterns included:

    APC_STUDY_EARLY_REPAIR_BOOTSTRAP_FC_O45_C_G
    apc-study-early-tools-fc-o45-c-g
    apcStudyEarlyToolsScratchFcO45CL
    APC_STUDY_SINGLE_OWNER_FC_O45_C_L
    APC_STUDY_TOOLS_AUTH_CLEANUP_FC_O45_C_K

The Study tools loader already calls authenticated controller routes such as:

    /api/study/decks
    /api/study/progress
    /api/study/decks/{deckId}/cards

This makes it a good place to add a small authenticated Companion Study action call.

## Existing route mapping

CL-S found `frontend/wrapper-ui/dev_server.py` maps:

    /api/study/* => controller
    /api/companion/* => controller

Relevant lines from the inventory:

    if path.startswith("/api/study/"):
        return CONTROLLER, path

    if path.startswith("/api/companion/"):
        return CONTROLLER, path

This means a UI call to:

    /api/companion/study/action

should route through the same controller path as the proven backend endpoint.

## Backend route map

CL-S found relevant backend routes:

    POST /api/companion/study/action
    POST /public/companion/study/action
    POST /api/companion/chat
    GET /api/companion/jobs/{job_id}/result
    GET /api/companion/voice/status
    POST /api/companion/voice/action
    POST /system/session/login
    GET /system/session/me
    POST /system/session/logout-safe

## Public unauthenticated safety proof during CL-S

CL-S verified:

    GET /api/system/status => HTTP 200
    GET /api/companion/voice/status => HTTP 200
    POST /api/companion/study/action action=last_message => HTTP 401
    POST /api/companion/study/action action=status => HTTP 401

No deterministic response was exposed without auth.

## Recommended minimal UI control

The first UI patch should be source-only and should add a minimal authenticated control that:

1. Mounts inside the existing wrapper Study tools or Companion area.
2. Uses the existing API helper style.
3. Calls:

       POST /api/companion/study/action

   with body:

       {
         "action": "last_message",
         "input_text": "<typed message>"
       }

4. Displays the deterministic response safely.
5. Handles 401 by showing a signed-in-required message instead of exposing errors.
6. Does not create jobs.
7. Does not call models.
8. Does not activate workers.
9. Does not touch public /var/www in the source-only step.

## Recommended next stage

CL-U should be source-only:

    patch frontend/wrapper-ui/app.js only
    add a minimal Study Companion last-message control
    add docs/smoke
    commit/tag/push

CL-U should not deploy.

A later CL-V should perform any public deploy only after CL-U source smoke proves:

    changed file is only frontend/wrapper-ui/app.js plus docs/smoke
    companion/study/action endpoint string appears once in the new control
    action last_message appears
    signed-out/401 handling is present
    no token literals are introduced
    no backend files changed
