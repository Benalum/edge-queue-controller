# Stage 17K R16AF — Study Card Images Disabled Panel Activation Guard Source-Only

This stage adds a source-only activation guard for the future study-card image panel.

The guard records the conditions needed before a later explicit visible-disabled-panel stage. It does not activate any UI by itself.

Safety posture:

- PPB-runnable.
- No interactive prompt.
- No remote SSH.
- No remote sudo.
- No deploy.
- Not loaded by index.html.
- No DOM mount.
- No active binding.
- No file picker.
- No image preview.
- No blob or IndexedDB write.
- No backup payload write.
- No backend upload.
- No Google Drive sync.
- No Anki or APKG mutation.
