#!/usr/bin/env bash
set -euo pipefail

test -f frontend/wrapper-ui/apc-wrapper-local/privatepages/admin/admin-users.js
test -f frontend/wrapper-ui/apc-wrapper-local/privatepages/admin/admin-users.css

grep -q 'APC_ADMIN_USERS_ADMIN_FOLDER_R3U' frontend/wrapper-ui/apc-wrapper-local/privatepages/admin/admin-users.js
grep -q '/api/admin/users' frontend/wrapper-ui/apc-wrapper-local/privatepages/admin/admin-users.js
grep -q '/system/admin/users' frontend/wrapper-ui/apc-wrapper-local/privatepages/admin/admin-users.js
grep -q '/privatepages/admin/admin-users.css?v=20260628-admin-users-r3u7' frontend/wrapper-ui/apc-wrapper-local/index.html
grep -q '/privatepages/admin/admin-users.js?v=20260628-admin-users-r3u7' frontend/wrapper-ui/apc-wrapper-local/index.html

node --check frontend/wrapper-ui/apc-wrapper-local/privatepages/admin/admin-users.js

echo "PASS: stage-16-r3u-admin-folder-frontend"

if grep -qE 'User support|Platform controls|Open System' frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/admin.html; then
  echo "FAIL: old admin placeholder content still present" >&2
  exit 1
fi
grep -q 'data-apc-admin-users-root' frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/admin.html

test -f frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/admin.html
grep -q 'data-apc-admin-users-root' frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/admin.html

if grep -qE 'User support|Platform controls|Open System' frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/admin.html; then
  echo "FAIL: old admin placeholder content still present in source admin page" >&2
  exit 1
fi

test -f frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js
grep -q '/privatepages/pages/admin.html?v=20260628-admin-users-r3u7' frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js

