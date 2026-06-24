#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="frontend/wrapper-ui/app.js"
DOC="docs/stage-16-fc-o45-d-f-recent-users-top50-scroll-credits.md"

echo "smoke_target_file=$TARGET_FILE"
echo "smoke_doc=$DOC"

test -f "$TARGET_FILE"
test -f "$DOC"

for needle in   "APC_RECENT_USERS_TOP50_CREDITS_FC_O45_D_F"   "Recent Users"   "Top 50 users by latest activity"   "Free/local credits"   "Paid credits"   "apcRecentUsersTop50CreditsFcO45DF"   "apc-recent-users-scroll"   "Credit columns ready"   "apcNativeAdminUsersFallbackFcO45DE"
do
  echo "check_source_contains=$needle"
  grep -qF "$needle" "$TARGET_FILE"
done

for needle in   "APC_RECENT_USERS_TOP50_CREDITS_FC_O45_D_F"   "Recent Users"   "top 50"   "free/local credits"   "paid credits"   "No CT203 backend mutation"   "No database write"   "No service restart"
do
  echo "check_doc_contains=$needle"
  grep -qiF "$needle" "$DOC"
done

if command -v node >/dev/null 2>&1; then
  node --check "$TARGET_FILE"
fi

echo "RESULT=PASS stage-16-fc-o45-d-f-recent-users-top50-scroll-credits"
