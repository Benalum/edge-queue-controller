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

| Public/API route | Controller route | Purpose |
|---|---|---|
| /api/account/credits | /system/account/credits | Account credit summary |
| /api/account/me | /system/account/me | Current user/session |
| /api/ads/reward/status | /system/ads/reward/status | Rewarded ad status |
| /api/ads/reward/claim | /system/ads/reward/claim | Rewarded ad mock/provider claim |
| /api/system/status | /system/status | Public system status |
| /api/system/presence/* | controller system presence routes | Web presence/power policy |
| /api/credits/reserve* | /system/credits/reserve* | Credit reservation |
| /api/credits/commit* | /system/credits/commit* | Credit commit |
| /api/credits/refund* | /system/credits/refund* | Credit refund |

## CT101-owned API routes

| Route | Owner | Purpose |
|---|---|---|
| /api/study/* | CT101 | Decks, cards, reviews, progress |
| /api/calendar/* | CT101 | Local calendar events |
| /api/companion-profile | CT101 | Companion profile |
| /api/jobs/* | CT101 | Job queue |
| /api/workers | CT101 | Worker status |
| /api/worker-nodes/* | CT101 | Worker node management |
| /api/public/platform-stats | CT101 | Public platform stats |

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

From controller repo, run:

    ops/smoke/check-all.sh

On CT101, run:

    cd /opt/ai-platform
    ops/smoke/check-ct101-owned-systems.sh

## Rule for new routes

Before adding a route, decide the owner first:

- Controller owns billing, credits, public wrapper auth/session, power, system status, and GPU credit reservations.
- CT101 owns study, companion, calendar, jobs, workers, and private app APIs.

Do not implement the same route in both systems.
