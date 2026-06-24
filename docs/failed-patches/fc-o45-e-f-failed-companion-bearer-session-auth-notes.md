# FC-O45-E-F failed Companion bearer-session auth patch

Status: preserved for diagnosis only; not deployed after rollback.

Why this artifact exists:
- FC-O45-E-F attempted to allow authenticated browser bearer sessions to call `/api/companion/chat` without requiring `EDGE_PUBLIC_API_KEY`.
- Initial injection malformed the `_require_public_api_key` function by inserting literal `\n` text into a comment line, causing runtime failures.
- R4 repaired that syntax shape but public `/api/system/status` and `/api/me` returned 502 after deploy, so CT203 was rolled back in FC-O45-E-F-R5.
- R5 restored a marker-free CT203 backend backup and verified:
  - public `/api/system/status` HTTP 200
  - public `/api/me` HTTP 401
  - signed-out companion POST HTTP 401
  - live CT203 backend no longer contained the E-F marker

Next safer approach:
- Do not patch `_require_public_api_key` globally.
- Prefer a route-local auth split:
  - `/public/companion/chat` keeps public API key requirement.
  - `/api/companion/chat` uses the existing bearer-session user resolver directly.
- Prove the route-local patch with static AST checks before any deploy.
