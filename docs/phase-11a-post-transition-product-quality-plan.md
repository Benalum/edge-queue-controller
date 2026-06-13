# Phase 11A Post-Transition Product Quality Plan

Phase 11A starts the post-transition phase after the completed Stage 10O transition baseline.

## Starting baseline

Final completed transition stage:

- Stage: Stage 10O
- Commit: 9c3572f test: checkpoint transition complete baseline stage 10o
- Tag: controller-stage-10o-transition-complete-operational-baseline-2026-06-12
- Result: PASS: Stage 10O commit and tag pushed - transition complete

## Phase 11 posture

The transition is complete.

Phase 11 must not extend transition stages unless a real regression appears.

Router rollout remains parked:

- Backend router dry-run stays disabled.
- Browser router traffic stays disabled.
- Persistent rollout mutation routes stay absent.
- Frontend router POST traffic stays absent.
- Logged-in/logged-out route boundaries stay unchanged.

Runtime services should not be restarted for Phase 11A.

## Phase 11A goal

Create a narrow, evidence-based product-quality checkpoint that decides the safest first improvement track after transition completion.

Phase 11A is documentation and read-only verification only.

## Evidence lesson from first Phase 11A attempt

The first Phase 11A smoke showed that `127.0.0.1:7070` may expose controller health while the full frontend/API route surface may be served through a different local gateway.

Phase 11A therefore uses adaptive GET-only gateway discovery instead of assuming one local port.

## Candidate Phase 11 tracks

1. UI polish and navigation cleanup.
2. Study feature improvements.
3. Companion feature improvements.
4. Final handoff and rollback documentation.
5. Route-specific frontend splitting to reduce app.js size.
6. Admin/System dashboard polish.
7. Calendar/provider planning.
8. Safer deployment and hardening checks.

## Recommended first implementation track

Recommended next track:

- Phase 11B: Admin/System dashboard polish plus navigation cleanup.

Reason:

- It is user-visible.
- It is low-risk.
- It should be testable with GET-only route checks.
- It does not require router rollout.
- It does not require provider integration.
- It does not require backend dry-run traffic.
- It does not require service restarts.
- It avoids changing logged-in/logged-out route boundaries.

## Phase 11B guardrails

Phase 11B should only improve presentation and clarity unless a stage explicitly says otherwise.

Allowed examples:

- Improve Admin/System dashboard layout.
- Make route cards, status cards, and navigation labels clearer.
- Add frontend-only empty/error/loading state polish.
- Add read-only status display improvements.
- Add smoke coverage for route availability and asset delivery.

Avoid in Phase 11B:

- No router rollout.
- No backend dry-run enablement.
- No frontend router POST traffic.
- No persistent rollout mutation routes.
- No logged-out access to full app pages.
- No service restarts unless explicitly required.
- No large route-splitting refactor yet.

## Later Phase 11 track order

Suggested order after Phase 11B:

1. Phase 11B: Admin/System dashboard polish and navigation cleanup.
2. Phase 11C: Public preview polish for logged-out users.
3. Phase 11D: Study page focused improvement.
4. Phase 11E: Companion page focused improvement.
5. Phase 11F: Route-specific frontend splitting/app.js reduction.
6. Phase 11G: Calendar/provider planning document.
7. Phase 11H: Safer deployment and hardening checks.
8. Phase 11I: Final handoff/rollback documentation refresh.

## Done criteria

Phase 11A is done when:

- This plan exists.
- A read-only smoke exists.
- The smoke verifies the Stage 10O baseline tag remains present.
- The smoke uses GET-only route checks.
- The smoke performs no runtime mutation.
- The smoke sends no POST traffic.
- The smoke does not restart services.
- The commit and tag are pushed only after the smoke passes.
