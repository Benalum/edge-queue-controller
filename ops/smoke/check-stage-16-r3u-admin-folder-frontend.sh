#!/usr/bin/env bash
set -euo pipefail

INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
ADMIN_JS="frontend/wrapper-ui/apc-wrapper-local/privatepages/admin/admin-users.js"
ADMIN_HTML="frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/admin.html"
COMPANION_HTML="frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/companion.html"

test -f "$INDEX"
test -f "$ADMIN_JS"
test -f "$ADMIN_HTML"
test -f "$COMPANION_HTML"

grep -q '/privatepages/admin/admin-users.css?v=20260629-admin-users-r3u12' "$INDEX"
grep -q '/privatepages/admin/admin-users.js?v=20260629-admin-users-r3u12' "$INDEX"
! grep -q 'admin-users-r3u10.js' "$INDEX"
! grep -q 'admin-users-r3u11.js' "$INDEX"

grep -q 'APC_ADMIN_USERS_MOUNT_ONLY_R3U12' "$ADMIN_JS"
grep -q 'apc-private-page-rendered' "$ADMIN_JS"
grep -q 'data-apc-admin-users-root' "$ADMIN_HTML"
grep -q 'id="companionPrivateApp"' "$COMPANION_HTML"

# Admin route ownership: admin-users.js must not write to #app directly.
! grep -q 'getElementById("app")' "$ADMIN_JS"
! grep -q "getElementById('app')" "$ADMIN_JS"
! grep -q 'app.innerHTML' "$ADMIN_JS"

# Companion fragment should not add its own second loading page.
! grep -q 'Loading Sol' "$COMPANION_HTML"

node --check "$ADMIN_JS"

echo "PASS: stage-16-r3u-r12-route-owned-admin-and-companion-fragments"
