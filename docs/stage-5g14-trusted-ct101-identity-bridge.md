# Stage 5G-14 — Trusted CT101 identity bridge for laptop queued chat

## Goal

Allow the laptop queued-chat controller to accept CT101-authenticated browser requests only when they come through the trusted laptop wrapper.

## What this fixes

The active CT101 ChatPage uses CT101 auth and CT101 chat ids. Stage 5G-13 showed the wrapper bridge reached the laptop controller, but the laptop controller rejected the CT101 token because it was not a laptop session.

## Safety

- Does not trust client-provided user_id.
- Does not send user_id from frontend app.js.
- Requires EDGE_TRUSTED_PROXY_SECRET on both wrapper and controller.
- Requires X-Edge-* identity headers from the trusted wrapper.
- Mirrors CT101 user/session/chat into laptop DB before using existing real-user queued-job creation.
- Queued chat remains disabled unless LAPTOP_CHAT_QUEUE_ENABLED=1.
- Wrapper app.js queued flag remains default false.
