# Stage 16 FC-O45-E-CA — Stable Study Companion Last-Message MVP

Date: 2026-06-24

## Scope

This checkpoint is source-only.

Allowed:
- active frontend source patch
- docs
- focused smoke
- git commit/tag/push

Not allowed:
- live deploy
- public /var/www mutation
- backend deploy
- CT203 runtime patch
- DB write
- job mutation
- result insert
- model/helper/Ollama call
- scheduler/timer/persistent-worker activation
- service change
- CT/VM restart
- nginx/cloudflared/sshd mutation
- storage mutation
- repo file deletion

## Recovery note

The first CA attempt selected an ignored archived app.js under .cleanup-archive and Node 22 rejected syntax checking an extensionless temporary file.

CA-R3 removes the accidental marker block from that ignored archive file if present, patches the active source file only, and syntax-checks a .js temporary smoke file.

## Intent

The Companion browser route proved model-backed jobs can complete, but the full chat SPA restore/polling behavior is too fragile for the current website shell.

CA changes the source direction to a stable Study Companion last-message MVP:

- render a stable Study Companion panel
- show Last AI answer from localStorage
- keep the last answer visible until Clear
- preserve a simple send form
- store the submitted prompt and returned job id
- show queued/running/completed/failed state honestly from saved state or one explicit status check
- avoid whole-page auto-refresh
- avoid long boot timers
- avoid repeating route restore loops
- keep Study action buttons as non-destructive placeholders

## Source target

Patched active frontend file:

```text
frontend/wrapper-ui/app.js
```

The source marker is:

```text
APC_STAGE16_FC_O45_E_CA_STUDY_COMPANION_MVP
```

## Runtime posture

No runtime was changed by this checkpoint. Deployment is intentionally deferred to the next approved phase.
