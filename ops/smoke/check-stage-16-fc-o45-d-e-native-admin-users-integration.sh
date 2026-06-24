#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="frontend/wrapper-ui/app.js"
DOC="docs/stage-16-fc-o45-d-e-native-admin-users-integration.md"

echo "smoke_target_file=$TARGET_FILE"
echo "smoke_doc=$DOC"

test -f "$TARGET_FILE"
test -f "$DOC"

for needle in   "APC_NATIVE_ADMIN_USERS_INTEGRATION_FC_O45_D_E"   "/system/admin/users"   "apcNativeAdminUsersIntegrationFcO45DE"   "Derived from /system/admin/users"   "Loaded from /system/admin/users"   "apcAdminUsersRouteRepairFcO45DCR2"   "removeTemporaryRepairPanel"
do
  echo "check_source_contains=$needle"
  grep -qF "$needle" "$TARGET_FILE"
done

for needle in   "APC_NATIVE_ADMIN_USERS_INTEGRATION_FC_O45_D_E"   "/system/admin/users"   "No CT203 backend mutation"   "No database write"   "No service restart"
do
  echo "check_doc_contains=$needle"
  grep -qF "$needle" "$DOC"
done

if command -v node >/dev/null 2>&1; then
  node --check "$TARGET_FILE"
fi

echo "RESULT=PASS stage-16-fc-o45-d-e-native-admin-users-integration"
