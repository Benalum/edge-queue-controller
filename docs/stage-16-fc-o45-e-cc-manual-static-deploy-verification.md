# Stage 16 FC-O45-E-CC — Manual Static Deploy Verification

Date: 2026-06-24

## Summary

FC-O45-E-CC deployed the stable Study Companion last-message MVP to the public VM200 static wrapper path after the source-only CA patch.

The final deploy was manual because:

- SSH to `website-edge` worked.
- `website-edge` did not have passwordless sudo.
- Root SSH targets were not available.
- The public webroot files were root-owned.

The user completed a bounded interactive sudo static install for only:

```text
/var/www/apc-wrapper-local/app.js
/var/www/apc-wrapper-local/index.html
```

No services were restarted.

## Public verification

PPB read-only verification FC-O45-E-CC-V1 confirmed:

```text
repo_clean=yes
public_root_http=200
public_app_http=200
public_ca_marker=yes
public_last_answer_mvp_present=yes
public_app_matches_local=yes
cache_bust=20260624fc045eccmanual2
local_app_sha=260756d06884743c4dbc3227e4e35920301d1411f1ec5ff681dedb63a1706f08
public_app_sha=260756d06884743c4dbc3227e4e35920301d1411f1ec5ff681dedb63a1706f08
```

## Runtime posture

No backend/runtime/database/model/job/scheduler/service mutation occurred during the PPB verification.

The manual static install touched only public static files:

- `index.html`
- `app.js`

## Current public frontend state

The public app now contains the CA marker:

```text
APC_STAGE16_FC_O45_E_CA_STUDY_COMPANION_MVP_START
```

The public app also contains the Study Companion MVP UI markers:

- Last AI answer
- Check status once
- Copy answer
- Use in Study
- Make flashcards
- Quiz me

## Next recommendation

Proceed to FC-O45-E-CE: browser behavior smoke for the simplified Study Companion panel.

CE should be read-only/browser-observation only:

- no source patch
- no deploy
- no service restart
- no backend mutation
- no DB/job/model mutation unless separately approved
