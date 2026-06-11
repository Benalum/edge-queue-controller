# Stage 5K-3 Study Wrapper Preview Route Audit — 2026-06-10

Audit-only stage before adding a non-default /study-wrapper-preview route.

Reason: Study app.js still contains standalone navigation/auth/hash routing code, so mounting it inside the wrapper should be done behind a preview route and in small reversible steps.

Next safe step: add /study-wrapper-preview as a wrapper route that loads the Study partial with CSS only, without running Study app.js yet.
