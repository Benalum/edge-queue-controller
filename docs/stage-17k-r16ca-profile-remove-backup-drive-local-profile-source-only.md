# Stage 17K R16CA — Profile cleanup: remove backup/Drive/local profile sections

## Goal

Keep Profile focused on companion setup and study source settings.

## Source-only changes

- Removed the static Local profile/account summary block from Profile.
- Stopped loading the Google Drive sync Profile panel.
- Stopped loading the complete local backup manager panel.
- Stopped loading the backup folder workspace panel.
- Stopped loading the older Buddies Who Study local backups diagnostics flow.
- Added a small Profile cleanup guard that removes cached/dynamic remnants if older scripts were already present in the page.

## Preserved

- Profile companion preset/settings.
- Custom companion media upload UI.
- Study card media helpers.
- Companion media display helpers.
- Local-first Study/Companion/Profile behavior.
- Support remains account-gated.

## Safety

No backend changes, no VM deploy, no SSH, no sudo, no Google Drive activation, no Anki writes, no deletion of local browser data.
