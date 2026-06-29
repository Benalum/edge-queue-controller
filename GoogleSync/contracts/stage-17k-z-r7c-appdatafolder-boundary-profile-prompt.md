# Stage 17K-Z-R7C appDataFolder Boundary and Profile Prompt

Status: source and contract only; no deploy
Date: 2026-06-29
Baseline commit before this stage: e7137e9

## Purpose

Change the GoogleSync proof from a visible Drive test file to a hidden Google Drive app data boundary.

The Profile prompt now tells users that AI Platform Control will only create and manage its own hidden Google Drive app data and will not browse, read, or modify other Drive files or folders.

## Storage Decision

- Use Google Drive `appDataFolder`.
- Use scope `https://www.googleapis.com/auth/drive.appdata`.
- Do not use a visible `.local` folder in Drive.
- Do not use broad Drive scope.
- Do not browse the user's Drive.
- Do not upload Anki files unless the user explicitly chooses import/convert later.

## Bootstrap Behavior

After a future deploy with a real OAuth Web client ID, the Profile page can:

1. Connect to Google with explicit consent.
2. Create `apc-google-sync-manifest.json` in `appDataFolder`.
3. Create `apc-google-sync-database.json` in `appDataFolder`.
4. Read metadata for APC app data files only.
5. Roll back by deleting the proof files by ID.

## Why appDataFolder

Google Drive appDataFolder is designed for app-specific data that the user should not directly interact with. It is hidden from the Drive UI and only accessible by the app that created it.

## Future Visible Folder Mode

If we later want users to choose a visible folder, that should be a separate mode using Google Picker and `drive.file` scope.

That future mode must clearly say it is user-visible and separate from hidden APC app data.

## Acceptance Criteria

- Profile module uses `drive.appdata`, not `drive.file`, for the hidden app data mode.
- Profile module writes files with parent `appDataFolder`.
- Profile prompt says APC will not browse, read, or modify other Drive files or folders.
- Profile prompt says Anki files are not uploaded by default.
- Source contains no broad Drive scope.
- No real client ID is committed.
- Existing GoogleSync validators pass.
- No deploy occurs in this stage.

## Next Recommended Stage

- Stage 17K-Z-R7D deploy appDataFolder Profile GoogleSync proof after a real Google OAuth Web client ID is available.
