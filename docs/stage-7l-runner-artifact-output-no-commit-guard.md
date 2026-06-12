# Stage 7L Runner Artifact Output No-Commit Guard

Stage 7L prevents future local authenticated shadow comparison artifacts from accidentally becoming commit candidates.

This stage does not change runtime behavior.

This stage does not wire the router into Study, Companion, or Chat.

## Purpose

Stage 7J created the manual local authenticated shadow comparison runner.

Stage 7K proved the runner is not runtime-wired.

Stage 7L adds commit-safety rules for runner output artifacts.

## Ignored output locations

Future local runner outputs should go under ignored locations:

- `ops/compare/output/`
- `docs/generated/authenticated-shadow-comparison-results/`

## Ignored file patterns

The repository should ignore local comparison output files matching:

- `*.auth-shadow-comparison.json`
- `*.authenticated-shadow-comparison.json`
- `*.local-auth-shadow.json`

## Allowed tracked examples

Tracked dry-run examples remain allowed:

- `docs/generated/stage-7g-study-authenticated-shadow-comparison-example-artifact.json`
- `docs/generated/stage-7g-companion-authenticated-shadow-comparison-example-artifact.json`

## Stage boundary

Stage 7L does not modify runtime handlers.

Stage 7L does not modify frontend behavior.

Stage 7L does not expose a new HTTP endpoint.

Stage 7L does not enable router dispatch.

Stage 7L does not enable router model calls.

Stage 7L does not store cookies, bearer tokens, passwords, or secrets.
