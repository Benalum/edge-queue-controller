# Stage 17K-Z-R11O-R2 — Rollback Commit Recovery, Keep Evidence

## Status

Rollback commit recovery checkpoint.

R11O already restored the live VM200 static files from the R11N backup and public/API smoke passed.

R11O failed later during repo staging because git revert tried to delete the R11M-R2 evidence docs. That deletion was not desired, so R11O-R2 keeps the evidence and commits only the source rollback plus rollback evidence.

## Live rollback

R11O restored VM200 from:

- /var/www/apc-wrapper-local/apc-r11n-canonical-profile-backup-20260701T051241Z

## Source rollback

The bad source canonicalization from commit 2a7fe0a is rolled back in app source files.

R11M-R2 evidence docs are intentionally kept.

## Why this is not a wrapper or bandage

This does not add another compatibility layer.

This does not add another Profile wrapper.

This removes the broken broad canonicalization and restores the prior working source behavior.

The duplicate Profile issue remains unresolved and should not be touched again without a narrower source diagnosis.

## Safety boundary

No deploy in R11O-R2.
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
