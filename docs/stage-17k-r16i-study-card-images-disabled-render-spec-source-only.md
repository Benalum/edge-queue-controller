# stage-17k-r16i-study-card-images-disabled-render-spec-source-only

R16I adds a source-only disabled render specification for optional study card images.

## Added

- \

## Scope

This stage defines the render shape for future question-side and answer-side image controls.
It does not mount UI, bind click handlers, open a picker, preview image bytes, write blobs, write IndexedDB, write backups, upload to the server, activate Google Drive sync, or mutate Anki/source files.

## Safety posture

- Source-only helper: yes.
- Loaded by \: no.
- Deployed: no.
- Mounted UI: no.
- Enabled controls: no.
- Image file picker: no.
- Image preview: no.
- Blob persistence: no.
- IndexedDB write: no.
- Backup payload write: no.
- Backend upload: no.
- Google Drive sync: no.
- Anki/source mutation: no.

## Prior proof baseline

R16H recorded browser proof \ at HEAD \ before this source-only addition.
