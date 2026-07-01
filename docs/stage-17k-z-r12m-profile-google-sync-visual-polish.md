# Stage 17K-Z-R12M — Profile Google Drive Sync Visual Polish

## Status

CSS-only VM200 static deploy.

## User goal

Make the Google Drive sync section look like the other private Profile boxes.

## Deployed files

Only two files were deployed:

- index.html
- privatepages/profile-private-polish.css

index.html changed only to cache-bust the Profile-specific stylesheet.

## Visual changes

The Profile stylesheet now adds Google Drive sync-specific styling:

- card border/background/shadow alignment with other boxes
- cleaner heading spacing
- consent checkbox area styled as an inset consent box
- scope/storage small text styled as a quiet info box
- ready status styled as a small badge when wrapped in strong text
- mobile-friendly consent layout

## Safety

No wrapper.
No broad shell rewrite.
No privatepages.js change.
No Profile fragment change.
No session gate change.
No private shell change.
No Google Drive sync JavaScript change.
No Google consent logic change.
No local backups logic change.
No Anki logic change.
No APKG mount change.
No backend route addition.
No DB write.
No signup change.
No server private Study persistence.
No Anki source file mutation.
No real SQLite collection parsing.
No media extraction.
No service restart.
