# Stage 7M Runner Authenticated Execution Manual Runbook

Stage 7M documents the safe manual procedure for running real local authenticated shadow comparisons.

This stage does not run authenticated comparisons.

This stage does not change runtime behavior.

This stage does not wire the router into Study, Companion, or Chat.

## Purpose

Stage 7J created the manual runner.

Stage 7K proved the runner is not runtime-wired.

Stage 7L ensured runner output artifacts are ignored and protected from accidental commits.

Stage 7M documents the exact manual procedure for a future real local authenticated comparison.

## Before running a real comparison

Run this first:

    cd ~/Desktop/edge-queue-controller || exit 1
    git status --short

The working tree should be clean except for intentional local ignored output artifacts.

## Authentication handling

Authenticate locally outside the repository.

Do not paste authentication values into docs, source files, shell history, commits, screenshots, or chat.

Use a shell prompt that does not echo the value:

    cd ~/Desktop/edge-queue-controller || exit 1

    export EDGE_AUTH_SHADOW_COMPARE_BASE_URL="http://127.0.0.1:7070"

    read -rsp "Paste runtime-only auth value: " EDGE_AUTH_SHADOW_COMPARE_COOKIE
    echo
    export EDGE_AUTH_SHADOW_COMPARE_COOKIE

Alternative bearer-token mode:

    cd ~/Desktop/edge-queue-controller || exit 1

    export EDGE_AUTH_SHADOW_COMPARE_BASE_URL="http://127.0.0.1:7070"

    read -rsp "Paste runtime-only bearer value: " EDGE_AUTH_SHADOW_COMPARE_BEARER
    echo
    export EDGE_AUTH_SHADOW_COMPARE_BEARER

Use exactly one auth mode at a time.

## Run Study comparison

Study comparison output should use an ignored path:

    cd ~/Desktop/edge-queue-controller || exit 1

    .venv/bin/python ops/compare/run-authenticated-shadow-comparison.py \
      --domain study \
      --case study_next \
      --execute-authenticated \
      --confirm-existing-route-call YES_EXISTING_ROUTE_MAY_CHANGE_STATE \
      --output ops/compare/output/study-next.manual.local-auth-shadow.json

Validate the artifact:

    python3 ops/validate/validate-authenticated-shadow-comparison-artifact.py \
      ops/compare/output/study-next.manual.local-auth-shadow.json

Confirm it is ignored:

    git check-ignore -v ops/compare/output/study-next.manual.local-auth-shadow.json
    git status --short ops/compare/output/study-next.manual.local-auth-shadow.json

## Run Companion comparison

Companion comparison output should use an ignored path:

    cd ~/Desktop/edge-queue-controller || exit 1

    .venv/bin/python ops/compare/run-authenticated-shadow-comparison.py \
      --domain companion \
      --case companion_chat \
      --execute-authenticated \
      --confirm-existing-route-call YES_EXISTING_ROUTE_MAY_CHANGE_STATE \
      --output ops/compare/output/companion-chat.manual.local-auth-shadow.json

Validate the artifact:

    python3 ops/validate/validate-authenticated-shadow-comparison-artifact.py \
      ops/compare/output/companion-chat.manual.local-auth-shadow.json

Confirm it is ignored:

    git check-ignore -v ops/compare/output/companion-chat.manual.local-auth-shadow.json
    git status --short ops/compare/output/companion-chat.manual.local-auth-shadow.json

## Cleanup

Always remove auth values from the shell after the manual run:

    unset EDGE_AUTH_SHADOW_COMPARE_COOKIE EDGE_AUTH_SHADOW_COMPARE_BEARER
    unset EDGE_AUTH_SHADOW_COMPARE_BASE_URL

Then verify the repository does not show local comparison outputs:

    git status --short

## Safety rules

Do not commit:

- auth values
- cookies
- bearer tokens
- passwords
- private keys
- raw authenticated response bodies
- raw personal chat content
- raw calendar data
- raw profile data
- local authenticated comparison artifacts

Only sanitized, intentionally reviewed examples should ever be tracked.

## Stage boundary

Stage 7M is a runbook only.

Stage 7M does not execute authenticated comparison commands.

Stage 7M does not expose a new HTTP endpoint.

Stage 7M does not modify runtime handlers.

Stage 7M does not modify frontend behavior.

Stage 7M does not enable router dispatch.

Stage 7M does not enable router model calls.
