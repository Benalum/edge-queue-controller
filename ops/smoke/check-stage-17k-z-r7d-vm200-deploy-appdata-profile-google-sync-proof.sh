#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 17K-Z-R7D VM200 deploy appDataFolder Profile GoogleSync source smoke ==="

INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MODULE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js"
CONTRACT_JSON="GoogleSync/contracts/stage-17k-z-r7d-vm200-deploy-appdata-profile-google-sync-proof.apc.json"

test -f "$INDEX"
test -f "$MODULE"
test -f "$CONTRACT_JSON"

python3 GoogleSync/validators/validate_google_sync_schemas.py
python3 GoogleSync/validators/validate_indexeddb_outbox_contract.py

python3 - <<'PY'
from pathlib import Path
import json, re, subprocess, sys

index = Path('frontend/wrapper-ui/apc-wrapper-local/index.html').read_text(encoding='utf-8')
module = Path('frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js').read_text(encoding='utf-8')
contract = json.loads(Path('GoogleSync/contracts/stage-17k-z-r7d-vm200-deploy-appdata-profile-google-sync-proof.apc.json').read_text(encoding='utf-8'))

if '/privatepages/google-sync-config.js?v=20260629-stage17k-z-r7d-appdata-vm200' not in index:
    raise SystemExit('index missing R7D VM200 runtime config script')
if 'APC_GOOGLE_SYNC_CONFIG_SCRIPT_STAGE_17K_Z_R7D_VM200_START' not in index:
    raise SystemExit('index missing R7D VM200 config marker')
if 'https://www.googleapis.com/auth/drive.appdata' not in module:
    raise SystemExit('module missing drive.appdata')
if 'appDataFolder' not in module:
    raise SystemExit('module missing appDataFolder')
if 'https://www.googleapis.com/auth/drive.file' in module:
    raise SystemExit('module must not use drive.file in appData mode')

checks = {
    'stage': contract.get('stage') == '17K-Z-R7D',
    'real_client_id_committed': contract.get('real_client_id_committed') is False,
    'client_id_runtime_only': contract.get('client_id_runtime_only') is True,
    'scope': contract.get('scope') == 'https://www.googleapis.com/auth/drive.appdata',
    'storage_space': contract.get('storage_space') == 'appDataFolder',
    'backend_deploy': contract.get('backend_deploy') is False,
}
failed = [key for key, ok in checks.items() if not ok]
if failed:
    raise SystemExit('contract checks failed: ' + ', '.join(failed))

client_id_pattern = re.compile(r'(?<!REPLACE_WITH_WEB_OAUTH_CLIENT_ID)([0-9]{6,}-[A-Za-z0-9_-]+[.]apps[.]googleusercontent[.]com)')
hits = []
for base in [Path('GoogleSync'), Path('frontend'), Path('public'), Path('src'), Path('ops')]:
    if not base.exists(): continue
    for path in base.rglob('*'):
        if not path.is_file(): continue
        if any(part in {'.git','node_modules','dist','build','.venv','venv','__pycache__'} for part in path.parts): continue
        try:
            text = path.read_text(encoding='utf-8')
        except UnicodeDecodeError:
            continue
        for match in client_id_pattern.finditer(text):
            hits.append(str(path) + ':' + match.group(1))
if hits:
    raise SystemExit('real-looking Google client ID committed: ' + '; '.join(hits))

allowed_prefixes = ('GoogleSync/', 'ops/smoke/check-stage-17k-z-r7d-vm200-deploy-appdata-profile-google-sync-proof.sh')
allowed_exact = {'frontend/wrapper-ui/apc-wrapper-local/index.html'}
out = subprocess.check_output(['git','status','--porcelain'], text=True)
bad = []
for line in out.splitlines():
    path = line[3:]
    if ' -> ' in path: bad.append(line)
    elif path in allowed_exact: continue
    elif path.startswith(allowed_prefixes): continue
    else: bad.append(line)
if bad:
    print('REFUSE: changed files outside R7D VM200 scope:')
    print('\n'.join(bad))
    sys.exit(1)

print('runtime_config_script=/privatepages/google-sync-config.js?v=20260629-stage17k-z-r7d-appdata-vm200')
print('scope=https://www.googleapis.com/auth/drive.appdata')
print('storage_space=appDataFolder')
print('PASS Stage 17K-Z-R7D VM200 source smoke')
PY
