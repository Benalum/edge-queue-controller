#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 17K-Z-R7 profile Google OAuth Drive dev proof smoke ==="

MODULE_SOURCE_PATH_FILE="GoogleSync/contracts/stage-17k-z-r6c-profile-google-sync-module-source-path.txt"
CONTRACT="GoogleSync/contracts/stage-17k-z-r7-profile-google-oauth-drive-dev-proof.apc.json"
DOC="GoogleSync/contracts/stage-17k-z-r7-profile-google-oauth-drive-dev-proof.md"

test -f "$MODULE_SOURCE_PATH_FILE"
test -f "$CONTRACT"
test -f "$DOC"
test -x GoogleSync/validators/validate_google_sync_schemas.py
test -x GoogleSync/validators/validate_indexeddb_outbox_contract.py

python3 GoogleSync/validators/validate_google_sync_schemas.py
python3 GoogleSync/validators/validate_indexeddb_outbox_contract.py

python3 - <<'PY'
from pathlib import Path
import json
import re
import subprocess
import sys

module_path = Path('GoogleSync/contracts/stage-17k-z-r6c-profile-google-sync-module-source-path.txt').read_text(encoding='utf-8').strip()
module = Path(module_path)
if not module.exists():
    raise SystemExit('Module source missing: ' + module_path)
text = module.read_text(encoding='utf-8')

required = [
    'APC_GOOGLE_SYNC_PROFILE_OAUTH_DRIVE_DEV_PROOF_STAGE_17K_Z_R7',
    'https://accounts.google.com/gsi/client',
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
    'https://www.googleapis.com/drive/v3/files',
    'window.google.accounts.oauth2.initTokenClient',
    'requestAccessToken',
    'explicit-consent',
    'data-apc-google-sync-explicit-consent',
    'Write harmless test file',
    'Read test file metadata',
    'Rollback/delete test file',
    'APC GoogleSync Dev Proof',
    "method: 'POST'",
    "method: 'GET'",
    "method: 'DELETE'",
    'sessionStorage',
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit('Module missing R7 required items: ' + ', '.join(missing))

scope_literals = re.findall(r'https://www[.]googleapis[.]com/auth/drive(?:[.][A-Za-z0-9_]+)?', text)
bad_scopes = sorted(set(scope for scope in scope_literals if scope != 'https://www.googleapis.com/auth/drive.file'))
if bad_scopes:
    raise SystemExit('Unexpected broad or unsupported Drive scope: ' + ', '.join(bad_scopes))

for forbidden in [
    'client_secret',
    'refresh_token',
    'localStorage.setItem(sessionKey',
    'localStorage.setItem(\'accessToken',
    'localStorage.setItem("accessToken',
    'password',
    'https://www.googleapis.com/auth/drive\'',
    'https://www.googleapis.com/auth/drive"',
]:
    if forbidden in text:
        raise SystemExit('Forbidden token/secret/broad-scope text in module: ' + forbidden)

if 'fetch(' not in text:
    raise SystemExit('R7 must include browser fetch calls for Drive dev proof source')

contract = json.loads(Path('GoogleSync/contracts/stage-17k-z-r7-profile-google-oauth-drive-dev-proof.apc.json').read_text(encoding='utf-8'))
if contract.get('stage') != '17K-Z-R7':
    raise SystemExit('Contract stage mismatch')
if contract.get('profile_only') is not True:
    raise SystemExit('Contract must be profile_only')
if contract.get('scope') != 'drive.file':
    raise SystemExit('Contract must record drive.file scope')
if contract.get('explicit_consent_required') is not True:
    raise SystemExit('Contract must require explicit consent')
if contract.get('token_storage') != 'memory_only':
    raise SystemExit('Contract must require memory-only token')
if contract.get('ppb_smoke_performs_oauth') is not False:
    raise SystemExit('PPB smoke must not perform OAuth')
if contract.get('ppb_smoke_performs_drive_write') is not False:
    raise SystemExit('PPB smoke must not perform Drive write')

marker = 'APC_GOOGLE_SYNC_PROFILE_OAUTH_DRIVE_DEV_PROOF_STAGE_17K_Z_R7'
hits = []
for base in [Path('frontend'), Path('public'), Path('src')]:
    if not base.exists():
        continue
    for path in base.rglob('*'):
        if not path.is_file():
            continue
        if any(part in {'.git', 'node_modules', 'dist', 'build', '.venv', 'venv', '__pycache__'} for part in path.parts):
            continue
        if path.suffix.lower() not in {'.js', '.html', '.css', '.ts', '.tsx', '.jsx'}:
            continue
        try:
            candidate = path.read_text(encoding='utf-8')
        except UnicodeDecodeError:
            continue
        if marker in candidate:
            hits.append(str(path))
if hits != [module_path]:
    raise SystemExit('R7 marker must appear only in Profile GoogleSync module. Hits: ' + ', '.join(hits))

allowed_exact = {
    module_path,
    'frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js',
    'ops/smoke/check-stage-17k-z-r7-profile-google-oauth-drive-dev-proof.sh',
    'ops/smoke/check-stage-17k-z-r6c-split-profile-google-sync-module.sh',
}
allowed_prefixes = ('GoogleSync/',)
out = subprocess.check_output(['git', 'status', '--porcelain'], text=True)
bad = []
for line in out.splitlines():
    path = line[3:]
    if ' -> ' in path:
        bad.append(line)
    elif path in allowed_exact:
        continue
    elif path.startswith(allowed_prefixes):
        continue
    else:
        bad.append(line)
if bad:
    print('REFUSE: changed files outside GoogleSync, Profile GoogleSync module, loader, and focused smokes:')
    for item in bad:
        print(item)
    sys.exit(1)

print('module_source=' + module_path)
print('scope=https://www.googleapis.com/auth/drive.file')
print('PASS Stage 17K-Z-R7 profile Google OAuth Drive dev proof smoke')
PY
