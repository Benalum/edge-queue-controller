# Stage 7G Authenticated Shadow Comparison Dry-Run Artifact Examples

Stage 7G creates safe example artifacts for future authenticated shadow comparisons.

This stage does not change runtime behavior.

This stage does not run authenticated comparisons.

This stage does not wire the router into Study, Companion, or Chat.

## Purpose

Stage 7C defined the authenticated shadow comparison artifact schema.

Stage 7D defined secret-handling guardrails.

Stage 7E added an offline artifact validator.

Stage 7F proved the validator is not runtime-wired.

Stage 7G creates safe example artifacts for both supported comparison domains:

- Study
- Companion

## Important boundary

The Stage 7G artifacts are examples only.

They do not use real authentication.

They do not call authenticated routes.

They do not store raw route responses.

They do not store cookies, tokens, passwords, or secrets.

They do not enable router dispatch.

They do not enable router model calls.

They do not change runtime wiring.

## Example artifacts

Stage 7G creates:

- `docs/generated/stage-7g-study-authenticated-shadow-comparison-example-artifact.json`
- `docs/generated/stage-7g-companion-authenticated-shadow-comparison-example-artifact.json`

Both artifacts must validate with:

- `ops/validate/validate-authenticated-shadow-comparison-artifact.py`

## Stage boundary

Stage 7G is artifact/example coverage only.

Stage 7G does not create authenticated automation.

Stage 7G does not expose a new HTTP endpoint.

Stage 7G does not modify runtime handlers.

Stage 7G does not modify frontend behavior.

Stage 7G does not enable router dispatch.

Stage 7G does not enable router model calls.
