#!/usr/bin/env bash
set -euo pipefail

test -f frontend/wrapper-ui/apc-wrapper-local/privatepages/admin/admin-users.js
test -f frontend/wrapper-ui/apc-wrapper-local/privatepages/admin/admin-users.css

grep -q 'APC_ADMIN_USERS_ADMIN_FOLDER_R3U' frontend/wrapper-ui/apc-wrapper-local/privatepages/admin/admin-users.js
grep -q '/api/admin/users' frontend/wrapper-ui/apc-wrapper-local/privatepages/admin/admin-users.js
grep -q '/system/admin/users' frontend/wrapper-ui/apc-wrapper-local/privatepages/admin/admin-users.js
grep -q '/privatepages/admin/admin-users.css?v=20260628-admin-users-r3u4' frontend/wrapper-ui/apc-wrapper-local/index.html
grep -q '/privatepages/admin/admin-users.js?v=20260628-admin-users-r3u4' frontend/wrapper-ui/apc-wrapper-local/index.html

node --check frontend/wrapper-ui/apc-wrapper-local/privatepages/admin/admin-users.js

echo "PASS: stage-16-r3u-admin-folder-frontend"
