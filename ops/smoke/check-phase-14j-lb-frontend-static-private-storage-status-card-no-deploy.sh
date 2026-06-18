#!/usr/bin/env bash
set -euo pipefail

APP="frontend/wrapper-ui/app.js"

if command -v node >/dev/null 2>&1; then
  node --check "$APP"
fi

python3 - <<'PY'
from pathlib import Path

text = Path("frontend/wrapper-ui/app.js").read_text()

required = [
    "function privateStorageInfrastructureDetail(storage)",
    "function privateStorageInfrastructureGroup(source = lastStatus)",
    "source?.private_storage_status",
    "Private backup storage policy:",
    "CT204 expected:",
    "authority:",
    "privateStorageInfrastructureGroup(source)",
    "groups[existingIndex] = storageGroup",
    "privateStorageInfrastructureGroup(lastStatus) || makeInfraGroup",
    "privateStorageInfrastructureGroup(cleanAdminSystem)",
    "storageDescription",
]

for needle in required:
    if needle not in text:
        raise SystemExit(f"missing required frontend marker: {needle}")

for forbidden in [
    "cryptsetup",
    "findmnt",
    "localStorage.setItem(\"private_storage_status",
    "fetch(\"/system/status\"",
]:
    if forbidden in text[text.index("function privateStorageInfrastructureDetail"):text.index("function normalizedPlatformGroups")]:
        raise SystemExit(f"forbidden storage card marker in helper block: {forbidden}")

print("PASS check-phase-14j-lb-frontend-static-private-storage-status-card-no-deploy")
PY
