# Stage 17K-Z-R11K — Live Browser Profile Anki Preview Proof Plan

## Status

Manual live-browser proof plan.

No deploy.
No frontend live mutation.
No backend route addition.
No server private Study persistence.
No DB write.
No signup change.
No Google Drive or OAuth work.
No email send.
No Anki source file mutation.
No local Study doc write.
No real SQLite collection parsing.
No media extraction.

## Current deployed checkpoint

R11J-R2 successfully deployed the Profile Anki preview static source chain to VM200 with a fresh cache-bust.

Latest deployed source chain:

- privatepages/anki-import-local.js
- privatepages/profile-anki-import-bridge.js
- privatepages/profile-anki-preview-panel.js
- privatepages/profile-anki-preview-mount.js

## Goal

Prove in a real browser that the Profile tab loads the local-only Anki APKG preview panel.

## Manual browser steps

1. Open:

   https://buddieswhostudy.com/

2. Sign in with an existing closed-beta account.

3. Open the Profile tab.

4. Confirm the page shows an Anki package preview panel.

5. Confirm the panel says the preview is local-only and does not upload or save anything.

6. Select a small `.apkg` file if available.

7. Click Preview locally.

8. Confirm the preview shows:

   - file name
   - file size
   - APKG container yes/no
   - collection.anki2 or collection.anki21 present
   - media manifest present yes/no
   - numeric media entry count
   - entry summaries
   - warnings

## Browser console verifier

Run this on the Profile page after the app loads:

    Promise.resolve().then(async () => {
      const result = {
        href: location.href,
        hasImporter: !!window.APC_ANKI_IMPORT_LOCAL,
        hasBridge: !!window.APC_PROFILE_ANKI_IMPORT_BRIDGE,
        hasPanel: !!window.APC_PROFILE_ANKI_PREVIEW_PANEL,
        hasMount: !!window.APC_PROFILE_ANKI_PREVIEW_MOUNT,
        importerMarker: window.APC_ANKI_IMPORT_LOCAL && window.APC_ANKI_IMPORT_LOCAL.apkgInspectorMarker,
        bridgeMarker: window.APC_PROFILE_ANKI_IMPORT_BRIDGE && window.APC_PROFILE_ANKI_IMPORT_BRIDGE.marker,
        panelMarker: window.APC_PROFILE_ANKI_PREVIEW_PANEL && window.APC_PROFILE_ANKI_PREVIEW_PANEL.marker,
        mountMarker: window.APC_PROFILE_ANKI_PREVIEW_MOUNT && window.APC_PROFILE_ANKI_PREVIEW_MOUNT.marker,
        mountNodePresent: !!document.querySelector('[data-apc-profile-anki-preview-mount="true"]'),
        panelNodePresent: !!document.querySelector('[data-apc-profile-anki-preview-panel="true"]'),
        fileInputPresent: !!document.querySelector('[data-apc-profile-anki-file="true"]'),
        previewButtonPresent: !!document.querySelector('[data-apc-profile-anki-preview-button="true"]'),
        statusText: document.querySelector('[data-apc-profile-anki-preview-status="true"]')?.textContent || null,
        pass: false
      };
      result.pass = result.hasImporter &&
        result.hasBridge &&
        result.hasPanel &&
        result.hasMount &&
        result.importerMarker === "APC_ANKI_IMPORT_LOCAL_APKG_CONTAINER_INSPECTOR_R11C" &&
        result.bridgeMarker === "APC_PROFILE_ANKI_IMPORT_BRIDGE_R11E" &&
        result.panelMarker === "APC_PROFILE_ANKI_PREVIEW_PANEL_R11F" &&
        result.mountMarker === "APC_PROFILE_ANKI_PREVIEW_MOUNT_R11G" &&
        result.mountNodePresent &&
        result.panelNodePresent &&
        result.fileInputPresent &&
        result.previewButtonPresent;
      console.log("APC_R11K_PROFILE_ANKI_BROWSER_PROOF", result);
      return result;
    });

## Expected pass result

The returned object should show:

- hasImporter true
- hasBridge true
- hasPanel true
- hasMount true
- mountNodePresent true
- panelNodePresent true
- fileInputPresent true
- previewButtonPresent true
- pass true

## Safety boundary

The manual proof must not:

- upload Anki data
- call private Study persistence routes
- write server data
- mutate the original Anki file
- activate Google Drive
- activate OAuth
- parse SQLite rows
- extract media files
