# Public Route Map

## Purpose

This document defines which system owns each public route.

The goal is to prevent duplicate pages, duplicate APIs, and confusion between:

- public alexhartel.com
- controller/laptop routes
- CT101 /opt/ai-platform
- Cloudflare Worker/public gateway routes
- internal CT101 frontend routes

## Ownership rule

Credits are owned by the controller.

CT101 must not expose or own credit wallets, credit ledgers, rewarded ads, or /api/credits/*.

## Public user-facing routes

| Public route | Owner | Source | Notes |
|---|---|---|---|
| / | Controller wrapper | frontend/wrapper-ui | Public shell/home |
| /credits | Controller wrapper + controller API | frontend/wrapper-ui/app.js, edge_controller.py | Public credit page |
| /login | Controller wrapper/auth | frontend/wrapper-ui, edge_controller.py | Public account login |
| /register | Controller wrapper/auth | frontend/wrapper-ui, edge_controller.py | Public account registration |
| /profile | Controller wrapper/account | frontend/wrapper-ui, edge_controller.py | Public profile/account |
| /study | CT101 study through public shell/proxy | CT101 /api/study/* | Study data belongs to CT101 |
| /companion | CT101 companion through public shell/proxy | CT101 companion routes | Companion data belongs to CT101 |
| /calendar | CT101 calendar through public shell/proxy | CT101 /api/calendar/* | Local calendar belongs to CT101 for now |
| /system | Controller wrapper/system | frontend/wrapper-ui, edge_controller.py | Public system status summary |

## Controller-owned API routes

Controller owns the following route prefixes:

| Route prefix | Purpose | Notes |
|---|---|---|
| /system/* | System status, power, presence | Core infrastructure |
| /public/* | Public gateway compatibility | Legacy/bridge routes |
| /api/auth/* | Login, logout, registration | Account authentication |
| /api/account/* | User profile, account settings | Account management |
| /api/credits/* | Credit reserve, commit, refund | Credit wallet operations |
| /api/ads/* | Rewarded ad status, claims | Advertising rewards |
| /api/jobs* | Public job bridge and polling | Public-facing edge job queue |

## System status routes

The controller exposes the following system status endpoints:

- `/system/status` — controller system health summary from `edge_controller.py`.
- `/system/public-status` — public wrapper status payload used by the public frontend.
- `/system/admin-status` — admin-only infrastructure status payload.
- `/public/status` — public job/worker summary payload only; not the same as full system health.

The public gateway path translates:

- `/api/system/status` → `/system/status`
- `/api/system/public-status` → `/system/public-status`
- `/api/system/admin-status` → `/system/admin-status`

`/public/status` is a public job/worker summary only, not a full system health response.
`/system/public-status` is the public wrapper status payload.
`/system/admin-status` is admin-only infrastructure status.

**All credit-related functionality is controller-owned.** CT101 must never own, expose, or route any credit API or data.

**Source-of-truth APIs:** The `/api/study/*`, `/api/companion/*`, and `/api/calendar/*` routes are CT101 source-of-truth APIs. Controller `/public/study/*` and `/public/companion/*` routes are only legacy public gateway bridges and must not become the authoritative data owner.

## CT101-owned API routes

CT101 owns the following route prefixes and behaviors:

| Route/feature | Owner | Purpose | Notes |
|---|---|---|---|
| /api/study/* | CT101 | Decks, cards, reviews, progress | CT101 source-of-truth spaced repetition API |
| /api/calendar/* | CT101 | Local calendar events | CT101 source-of-truth calendar API |
| /api/companion/* | CT101 | Companion profile and chat | CT101 source-of-truth companion API |
| /api/worker-nodes/* | CT101 | Worker node management | Worker pool administration |
| /api/public/platform-stats | CT101 | Public platform stats | Read-only platform metrics |
| Job execution & scheduler | CT101 | Durable backend job runner, worker management, scheduler | Async task processing, workers, model execution |

**Stage 1 note:** CT101 is not modified in this stage. These route ownerships are documented as they currently exist.

**Stage 2A note:** This stage documents current system status routes and validates them with read-only smoke checks only. No runtime behavior changes. No CT101 changes. No power automation or Wake-on-LAN changes.

## Cloudflare Worker translation routes

The public Cloudflare Worker still translates some public `/api/*` routes into controller `/public/*` or `/system/*` routes.

| Public Worker route | Controller route | Owner | Notes |
|---|---|---|---|
| `/api/status` | `/public/status` | Controller | Public controller status |
| `/api/me` | `/public/me` | Controller | Public auth/session user |
| `/api/auth/*` | `/public/auth/*` | Controller | Login/register/logout bridge |
| `/api/jobs` | `/public/jobs` | Controller | Public Ollama job queue bridge |
| `/api/jobs/*` | `/public/jobs/*` | Controller | Public job polling bridge |
| `/api/study/*` | `/public/study/*` | Controller legacy/public bridge | Still routed by Worker |
| `/api/companion/*` | `/public/companion/*` | Controller legacy/public bridge | Still routed by Worker |
| `/api/system/*` | `/system/*` | Controller system routes | System status/power bridge |

These routes are part of the public gateway path and should not be confused with CT101 private `/api/study/*`, `/api/calendar/*`, or `/api/worker-nodes/*`.

## Stage 1: Route ownership stabilization

**Scope:** Documentation and non-destructive validation only. CT101 is not modified in Stage 1.

**Objective:** Clarify route ownership boundaries and document current state to prevent future conflicts.

**Checklist:**

- [x] Document clear controller-owned route prefixes
- [x] Document clear CT101-owned route prefixes
- [x] Note that study, companion, calendar private APIs belong to CT101
- [x] Note that job execution and worker management belong to CT101
- [x] Confirm all credit functionality is controller-owned
- [x] Document that duplicate route ownership should be avoided
- [ ] Validate no controller routes are shadowed by CT101
- [ ] Validate no CT101 routes are shadowed by controller
- [ ] Review Cloudflare Worker translation routes for conflicts
- [ ] Audit public_gateway.py route dispatch logic
- [ ] Confirm frontend routing matches this map
- [ ] Run non-destructive controller smoke check

**Notes for subsequent stages:**

- Route conflicts (if found in validation) must be documented, not fixed, in Stage 1.
- CT101 modification and deployment happens in later stages.
- When actively running Stage 1 implementation/testing, pause power automation so PVESO/CT101 are not stopped mid-check.

## Forbidden CT101 routes/tables

The following must not exist in CT101:

- /api/credits/*
- /api/credits/balance
- /api/credits/rewarded/status
- /api/credits/rewarded/start
- /api/credits/rewarded/claim
- user_credit_wallets
- credit_ledger
- rewarded_ad_sessions
- backend/app/routes/rewarded_credits.py
- frontend/app/credits/page.tsx

This is enforced by:

- controller: ops/smoke/check-credit-ownership.sh
- CT101: ops/smoke/check-ct101-owned-systems.sh

## Required checks before route/API changes

**For controller-only Stage 1 work (documentation and validation):**

From controller repo, run:

    ops/smoke/check-all.sh

**For CT101 route/API changes (later stages):**

On CT101, run:

    cd /opt/ai-platform
    ops/smoke/check-ct101-owned-systems.sh

Note: The CT101 smoke check is required before any CT101 route/API changes, not during this Stage 1 controller-only documentation pass unless explicitly instructed.

## Rule for new routes

Before adding a route, decide the owner first:

- Controller owns billing, credits, public wrapper auth/session, power, system status, and GPU credit reservations.
- CT101 owns study, companion, calendar, jobs, workers, and private app APIs.

Do not implement the same route in both systems.
