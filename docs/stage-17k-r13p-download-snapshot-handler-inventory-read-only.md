# Stage 17K-R13P — Download Snapshot Handler Inventory Read-Only

## Status

Read-only source inventory.

## Purpose

Locate the current Download snapshot button/handler and the exact backup export path before wiring sanitized snapshot output.

## Why

R13O added a prepare-only sanitized snapshot output helper. Before changing live Download snapshot behavior, this stage records the current handler shape so the next patch can be narrow and avoid guessing.

## Safety

Docs/evidence only.

No source mutation.
No frontend deploy.
No backend deploy.
No runtime mutation.
No service restart.
No DB write.
No signup change.
No Google Drive or OAuth activation.
No server private Study persistence.
No Anki source file mutation.
No local Study restore write.
No browser download behavior change.
No same-file write path.
