# Stage 17K R16BU — local-first Study, Companion, Profile, support gate

This stage changes the wrapper source only.

## What changed

- Study, Companion, and Profile are local-first app routes.
- Signed-out users can open Study, Companion, and Profile.
- Support remains account-gated.
- System is removed from the main header and public home card grid.
- Public route ownership is reduced to the home page.
- Existing private app fragments now render Study, Companion, and Profile without requiring a token by using a browser-local user object.
- Profile gains a local settings panel.
- Companion name, listening video URL, and talking video URL can be edited locally from Companion and Profile.
- Support gains a source frontend for create/list/open/reply ticket flows against the existing account-gated support endpoints.

## Safety rails

- No VM deploy.
- No SSH.
- No sudo.
- No backend route mutation.
- No database mutation.
- No Anki mutation.
- No Google Drive sync activation.
- No private backup write.
- No study data server persistence reintroduction.

## Expected route model

- `/` is the public home page.
- `/study` renders the local Study workspace.
- `/companion` renders Companion and local Companion settings.
- `/profile` renders local profile settings.
- `/support` requires login.
- `/system` is removed from the normal navigation.
