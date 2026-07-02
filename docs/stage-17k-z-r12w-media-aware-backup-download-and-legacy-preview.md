# Stage 17K-Z-R12W — Media-Aware Backup Download and Legacy Preview

## Status

Narrow VM200 static deploy.

## User-facing fix

Downloaded local backup files now use a media-aware backup shape.

New downloads include empty media docs:

- study/media/v1
- study/media-blobs/v1
- study/card-media-refs/v1
- study/media-manifest/v1
- study/anki-media/v1
- study/anki-imports/v1

Backup filenames now use v2.

## Legacy compatibility

The restore preview helper now accepts old v1 backup files where docs are an array of key/value entries and privacy fields use legacy names.

Missing media docs in old v1 backups are warnings, not restore preview failures.

## Safety

Preview only.
No restore write path.
No backend deploy.
No runtime mutation.
No service restart.
No DB write.
No signup change.
No Google Drive or OAuth activation.
No server private Study persistence.
No Anki source file mutation.
No Anki scheduling mutation.
No local Study restore write.
No media blob persistence.
No media extraction.
No SQLite parsing execution.
No Companion model/helper call.
No privatepages.js change.
No Profile fragment change.
