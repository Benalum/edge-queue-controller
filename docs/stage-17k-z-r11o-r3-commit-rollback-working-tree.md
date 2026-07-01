# Stage 17K-Z-R11O-R3 — Commit Rollback Working Tree

## Status

Rollback commit recovery checkpoint.

R11O already restored live VM200 static files from the R11N backup. Public smoke and API guard passed.

R11O-R2 confirmed the live rollback still held, but stopped on a whitespace check while the source rollback was still in the working tree.

R11O-R3 commits that already-prepared source rollback and keeps the R11M-R2 evidence docs.

## What this stage does

- Does not deploy.
- Does not add a wrapper.
- Does not add a bandage.
- Keeps R11M-R2 evidence docs.
- Commits the source rollback of the bad broad Profile canonicalization.
- Records rollback recovery evidence.

## Live status

The bad R11N live deploy was already rolled back to the R11N backup:

- /var/www/apc-wrapper-local/apc-r11n-canonical-profile-backup-20260701T051241Z

## Bad source rollback

The bad source canonicalization from commit 2a7fe0a is reverted from app source files.

## Safety boundary

No deploy in R11O-R3.
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
