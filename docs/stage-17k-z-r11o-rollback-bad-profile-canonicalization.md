# Stage 17K-Z-R11O — Rollback Bad Profile Canonicalization

## Status

Emergency rollback checkpoint.

R11N deployed the R11M-R2 Profile canonicalization source fix, but manual browser testing showed a serious regression: clicking app navigation caused the page to go white and display "Checking session."

This rollback intentionally removes the bad canonicalization from live VM200 static files and reverts the bad source commit.

## What was rolled back

Live VM200 static files were restored from the R11N backup directory.

Reverted bad source commit:

- 2a7fe0a fix: remove duplicate profile render path

## Why this is not a wrapper or bandage

This does not add another compatibility layer.

This removes the broken broad canonicalization and restores the last known working static behavior.

The duplicate Profile issue remains unresolved after rollback and must be addressed later with a narrower removal patch that does not alter the private shell/session render path.

## Safety boundary

No backend route addition.
No server private Study persistence.
No DB write.
No signup change.
No Google Drive or OAuth activation.
No email send.
No Anki source file mutation.
No local Study doc write.
No real SQLite collection parsing.
No media extraction.
No service restart.
No nginx reload.
No cloudflared mutation.

## Next direction

Do not patch privatepages.js broadly.

Do not add a wrapper.

Next diagnosis should isolate the exact stale Profile loader and remove only that loader after proving header navigation and hard refresh use the same event lifecycle.
