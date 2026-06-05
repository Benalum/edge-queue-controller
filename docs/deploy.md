# Deploy Notes

## Purpose

This document defines how each part of the system is deployed.

The goal is to avoid confusion between:

- public alexhartel.com wrapper
- controller/laptop service
- CT101 ai-platform Docker app
- Cloudflare Worker/public gateway

## Systems

### Controller repo

Path:

    ~/Desktop/edge-queue-controller

Owns:

- public wrapper source
- controller API
- credits
- rewarded ads
- GPU credit reservations
- system status/power
- public gateway/worker code

Important files:

- edge_controller.py
- public_gateway.py
- frontend/wrapper-ui/app.js
- frontend/wrapper-ui/index.html
- cloudflare/edge-public-proxy/src/index.js
- ops/smoke/check-all.sh

### CT101 app

Path:

    root@100.88.194.19 -> pct exec 101 -> /opt/ai-platform

Owns:

- study
- companion
- calendar
- jobs/workers
- CT101 private frontend
- CT101 private backend

Does not own:

- credits
- rewarded ads
- /api/credits/*
- credit ledger tables

## Required checks before deploy/refactor

From controller repo:

    cd ~/Desktop/edge-queue-controller
    ops/smoke/check-all.sh

On CT101:

    ssh root@100.88.194.19 'pct exec 101 -- bash -lc "
    cd /opt/ai-platform
    ops/smoke/check-ct101-owned-systems.sh
    "'

## Controller service deploy

The controller runs as a systemd service on the laptop.

Check status:

    sudo systemctl status edge-queue-controller --no-pager

Restart:

    sudo systemctl restart edge-queue-controller

After restart:

    ops/smoke/check-all.sh

## Public wrapper deploy

Public wrapper source lives in:

    frontend/wrapper-ui

Important files:

- index.html
- app.js
- styles.css

If app.js changes, bump the script version in index.html to avoid stale browser/cache behavior.

Example:

    <script src="/app.js?v=YYYYMMDDHHMMSS"></script>

After wrapper changes:

    ops/smoke/check-all.sh

Then verify public app is serving the expected version:

    curl -sL https://alexhartel.com/credits | grep -o 'app.js?v=[0-9]*' | head

## CT101 deploy

CT101 is deployed with Docker Compose inside CT101.

Run:

    ssh root@100.88.194.19 'pct exec 101 -- bash -lc "
    cd /opt/ai-platform
    docker compose up -d --build
    ops/smoke/check-ct101-owned-systems.sh
    "'

If only API changed:

    ssh root@100.88.194.19 'pct exec 101 -- bash -lc "
    cd /opt/ai-platform
    docker compose up -d --build --force-recreate api
    ops/smoke/check-ct101-owned-systems.sh
    "'

If only frontend changed:

    ssh root@100.88.194.19 'pct exec 101 -- bash -lc "
    cd /opt/ai-platform
    docker compose up -d --build --force-recreate frontend
    ops/smoke/check-ct101-owned-systems.sh
    "'

## Cloudflare/public gateway

Cloudflare Worker/public gateway code may route browser/API traffic to the controller or CT101.

Important files:

- public_gateway.py
- cloudflare/edge-public-proxy/src/index.js
- cloudflare/edge-public-proxy/wrangler.jsonc

Before changing gateway behavior, update:

- docs/public-route-map.md
- docs/deploy.md if deploy flow changes

Then run:

    ops/smoke/check-all.sh

and:

    ssh root@100.88.194.19 'pct exec 101 -- bash -lc "
    cd /opt/ai-platform
    ops/smoke/check-ct101-owned-systems.sh
    "'

## Commit rules

Use one commit per purpose.

Good:

- Add public route ownership docs
- Extract rewarded ad status helper
- Fix rewarded ad status smoke test
- Update wrapper app.js cache version

Bad:

- Mix credit cleanup, frontend UI, model default, and gateway edits in one commit

## Rollback tags

Known good controller tags:

- clean-credit-ownership-2026-06-05
- controller-refactor-helpers-green-2026-06-05
- controller-smoke-all-green-2026-06-05

Known good CT101 tag:

- clean-ct101-owned-systems-2026-06-05

## Golden rule

Before adding or changing a route, decide the owner first.

Controller owns billing, credits, public wrapper auth/session, power, system status, and GPU credit reservations.

CT101 owns study, companion, calendar, jobs, workers, and private app APIs.

Do not duplicate ownership.
