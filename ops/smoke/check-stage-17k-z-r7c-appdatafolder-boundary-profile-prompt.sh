#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 17K-Z-R7C appDataFolder boundary Profile prompt smoke ==="

MODULE_PATH_FILE="GoogleSync/contracts/stage-17k-z-r6c-profile-google-sync-module-source-path.txt"
CONTRACT_JSON="GoogleSync/contracts/stage-17k-z-r7c-appdatafolder-boundary-profile-prompt.apc.json"
CONTRACT_MD="GoogleSync/contracts/stage-17k-z-r7c-appdatafolder-boundary-profile-prompt.md"

test -f "$MODULE_PATH_FILE"
test -f "$CONTRACT_JSON"
test -f "$CONTRACT_MD"
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
    raise SystemExit('module missing: ' + module_path)
text = module.read_text(encoding='utf-8')

required = [
    'APC_GOOGLE_SYNC_PROFILE_APPDATA_BOUNDARY_STAGE_17K_Z_R7C',
    'https://www.googleapis.com/auth/drive.appdata',
    "const appDataSpace = 'appDataFolder'",
    'parents: [appDataSpace]',
    'spaces=appDataFolder',
    'AI Platform Control will only create and manage its own hidden Google Drive app data',
    'will not browse, read, or modify your other Drive files or folders',
    'will not upload Anki files unless I explicitly choose an import/convert option later',
    'apc-google-sync-manifest.json',
    'apc-google-sync-database.json',
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit('module missing required appDataFolder boundary items: ' + ', '.join(missing))

for forbidden in [
    'https://www.googleapis.com/auth/drive\'',
    'https://www.googleapis.com/auth/drive"',
    'https://www.googleapis.com/auth/drive.file',
    'client_secret',
    'refresh_token',
    'localStorage.setItem(sessionKey',
    'localStorage.setItem(\'accessToken',
    'localStorage.setItem("accessToken',
]:
    if forbidden in text:
        raise SystemExit('forbidden broad/token text in module: ' + forbidden)

contract = json.loads(Path('GoogleSync/contracts/stage-17k-z-r7c-appdatafolder-boundary-profile-prompt.apc.json').read_text(encoding='utf-8'))
checks = {
    'stage': contract.get('stage') == '17K-Z-R7C',
    'scope': contract.get('scope') == 'https://www.googleapis.com/auth/drive.appdata',
    'storage_space': contract.get('storage_space') == 'appDataFolder',
    'user_visible_drive_folder': contract.get('user_visible_drive_folder') is False,
    'can_browse_user_drive': contract.get('can_browse_user_drive') is False,
    'real_client_id_committed': contract.get('real_client_id_committed') is False,
    'frontend_deployed_in_this_stage': contract.get('frontend_deployed_in_this_stage') is False,
}
failed = [key for key, ok in checks.items() if not ok]
if failed:
    raise SystemExit('contract checks failed: ' + ', '.join(failed))

client_id_pattern = re.compile(r'(?<!REPLACE_WITH_WEB_OAUTH_CLIENT_ID)([0-9]{6,}-[A-Za-z0-9_-]+[.]apps[.]googleusercontent[.]com)')
hits = []
for base in [Path('GoogleSync'), Path('frontend'), Path('public'), Path('src'), Path('ops')]:
    if not base.exists():
        continue
    for path in base.rglob('*'):
        if not path.is_file():
            continue
        if any(part in {'.git', 'node_modules', 'dist', 'build', '.venv', 'venv', '__pycache__'} for part in path.parts):
            continue
        try:
            candidate = path.read_text(encoding='utf-8')
        except UnicodeDecodeError:
            continue
        for match in client_id_pattern.finditer(candidate):
            hits.append(str(path) + ':' + match.group(1))
if hits:
    raise SystemExit('real-looking Google OAuth client ID committed: ' + '; '.join(hits))

allowed_exact = {
    module_path,
    'frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js',
    'ops/smoke/check-stage-17k-z-r7c-appdatafolder-boundary-profile-prompt.sh',
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
    print('REFUSE: changed files outside appDataFolder boundary scope:')
    for item in bad:
        print(item)
    sys.exit(1)

print('module_source=' + module_path)
print('scope=https://www.googleapis.com/auth/drive.appdata')
print('storage_space=appDataFolder')
print('PASS Stage 17K-Z-R7C appDataFolder boundary Profile prompt smoke')
PY
