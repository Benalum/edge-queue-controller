# Stage 16 FC-O45-E-CG-B — Study Companion Surface Owner Source Patch

Date: 2026-06-25

## Scope

This checkpoint is source-only.

Allowed:
- active frontend source patch
- docs
- focused smoke
- git commit/tag/push

Not allowed:
- deploy
- public `/var/www` mutation
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

## Why this patch exists

FC-O45-E-CF-R2 proved a real browser public Companion submit works. The browser created job `573` and rendered an assistant answer.

But the visible route was still the legacy Conversation UI, and it kept showing `Status: queued` even after rendering an assistant answer. The CA localStorage keys were also not populated by that legacy path.

The first CG-B attempt failed before changing source because Python `re.sub` interpreted JavaScript regex backslashes inside the replacement block.

## What CG-B-R2 changes

CG-B-R2 appends a surface-owner override block instead of replacing the existing CA block.

The owner block:

- owns `/companion` and `/study`
- uses a single `MutationObserver`, not timers, to recover if legacy rendering removes the panel
- avoids reloads and route-poke loops
- wraps browser `fetch` so legacy submit/status/result responses can populate CA localStorage keys
- records prompt, job id, status, note, updated time, and answer into:
  - `apc.studyCompanion.lastAnswer`
  - `apc.studyCompanion.lastPrompt`
  - `apc.studyCompanion.lastJobId`
  - `apc.studyCompanion.status`
  - `apc.studyCompanion.updatedAt`
  - `apc.studyCompanion.note`
- adopts visible legacy `Job N` and `Assistant ...` text before replacing the legacy view
- shows `completed` when an assistant answer is visible instead of leaving the panel as `queued`
- includes `/api/chat/queued` in the submit/status endpoint list because that is the path that created browser job 573

## Runtime posture

No runtime was changed by this checkpoint. Public deployment is deferred to a later approved static deploy phase.
