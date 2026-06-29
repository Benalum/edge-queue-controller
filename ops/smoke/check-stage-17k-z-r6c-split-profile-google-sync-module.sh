#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 17K-Z-R6C split Profile GoogleSync module smoke ==="

R6_SOURCE_PATH_FILE="GoogleSync/contracts/stage-17k-z-r6-profile-ui-source-path.txt"
MODULE_SOURCE_PATH_FILE="GoogleSync/contracts/stage-17k-z-r6c-profile-google-sync-module-source-path.txt"
CONTRACT="GoogleSync/contracts/stage-17k-z-r6c-split-profile-google-sync-module.md"
LIB_DECISION="GoogleSync/contracts/stage-17k-z-r6c-official-library-decision.apc.json"

test -f "$R6_SOURCE_PATH_FILE"
test -f "$MODULE_SOURCE_PATH_FILE"
test -f "$CONTRACT"
test -f "$LIB_DECISION"
test -x GoogleSync/validators/validate_google_sync_schemas.py
test -x GoogleSync/validators/validate_indexeddb_outbox_contract.py

python3 GoogleSync/validators/validate_google_sync_schemas.py
python3 GoogleSync/validators/validate_indexeddb_outbox_contract.py

python3 - <<'PY'
from pathlib import Path
import json
import subprocess
import sys

loader_marker = 'APC_GOOGLE_SYNC_PROFILE_LOADER_MARKER_STAGE_17K_Z_R6C'
legacy_marker = 'APC_GOOGLE_SYNC_PROFILE_ONLY_MARKER_STAGE_17K_Z_R6'
module_marker = 'APC_GOOGLE_SYNC_PROFILE_MODULE_MARKER_STAGE_17K_Z_R6C'
loader_start = '/* APC_GOOGLE_SYNC_PROFILE_ONLY_STAGE_17K_Z_R6_START */'
loader_end = '/* APC_GOOGLE_SYNC_PROFILE_ONLY_STAGE_17K_Z_R6_END */'
module_start = '/* APC_GOOGLE_SYNC_PROFILE_MODULE_STAGE_17K_Z_R6C_START */'
module_end = '/* APC_GOOGLE_SYNC_PROFILE_MODULE_STAGE_17K_Z_R6C_END */'

loader_path = Path('GoogleSync/contracts/stage-17k-z-r6-profile-ui-source-path.txt').read_text(encoding='utf-8').strip()
module_path = Path('GoogleSync/contracts/stage-17k-z-r6c-profile-google-sync-module-source-path.txt').read_text(encoding='utf-8').strip()
loader = Path(loader_path)
module = Path(module_path)

if not loader.exists():
    raise SystemExit('Loader source missing: ' + loader_path)
if not module.exists():
    raise SystemExit('Module source missing: ' + module_path)
if loader_path == module_path:
    raise SystemExit('Loader and module must be separate files')
if module.name != 'profile-google-sync-panel.js':
    raise SystemExit('Module should be profile-google-sync-panel.js')

loader_text = loader.read_text(encoding='utf-8')
module_text = module.read_text(encoding='utf-8')

if loader_start not in loader_text or loader_end not in loader_text:
    raise SystemExit('Loader missing R6 compatibility block delimiters')
loader_block = loader_text.split(loader_start, 1)[1].split(loader_end, 1)[0]
if loader_marker not in loader_block:
    raise SystemExit('Loader missing R6C loader marker')
if legacy_marker not in loader_block:
    raise SystemExit('Loader missing legacy R6 marker for traceability')
if 'profile-google-sync-panel.js' not in loader_block:
    raise SystemExit('Loader does not reference new module')
if 'document.createElement(\'section\')' in loader_block or 'panel.innerHTML' in loader_block:
    raise SystemExit('Loader still contains panel rendering code')

if module_start not in module_text or module_end not in module_text:
    raise SystemExit('Module missing R6C block delimiters')
module_block = module_text.split(module_start, 1)[1].split(module_end, 1)[0]
required_module_items = [
    module_marker,
    'APC_PROFILE_GOOGLE_SYNC_PANEL_STAGE_17K_Z_R6C',
    'officialLibraryDecision',
    'Google Identity Services JavaScript authorization client',
    'Google Drive REST API',
    'Google Picker for user-selected files and folders',
    'drive.file',
    'Google Drive sync',
    'Not connected',
    'Connect Google Drive',
    'Sync now',
    'data-apc-google-sync-profile-only',
    'data-apc-google-sync-oauth-active',
    'data-apc-google-sync-drive-reads',
    'data-apc-google-sync-drive-writes',
    'isProfileSurface',
]
missing = [item for item in required_module_items if item not in module_block]
if missing:
    raise SystemExit('Module missing required items: ' + ', '.join(missing))

for label, block in [('loader', loader_block), ('module', module_block)]:
    for forbidden in [
        'fetch(',
        'XMLHttpRequest',
        'sendBeacon',
        'gapi.client',
        'gapi.auth',
        'googleapis.com/drive',
        'oauth2.googleapis.com',
        'accounts.google.com',
        'window.open',
        'location.href',
        'drive.write',
    ]:
        if forbidden in block and 'APC_GOOGLE_SYNC_PROFILE_OAUTH_DRIVE_DEV_PROOF_STAGE_17K_Z_R7' not in block:
            raise SystemExit(f'Forbidden activation/API/navigation text in {label} block: {forbidden}')

decision = json.loads(Path('GoogleSync/contracts/stage-17k-z-r6c-official-library-decision.apc.json').read_text(encoding='utf-8'))
if decision.get('custom_oauth_implementation') is not False:
    raise SystemExit('Library decision must reject custom OAuth')
if decision.get('oauth_activated_in_this_stage') is not False:
    raise SystemExit('R6C must not activate OAuth')
if decision.get('drive_reads_in_this_stage') is not False:
    raise SystemExit('R6C must not read Drive')
if decision.get('drive_writes_in_this_stage') is not False:
    raise SystemExit('R6C must not write Drive')
if decision.get('preferred_scope') != 'drive.file':
    raise SystemExit('Preferred scope must remain drive.file')

module_marker_hits = []
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
            text = path.read_text(encoding='utf-8')
        except UnicodeDecodeError:
            continue
        if module_marker in text:
            module_marker_hits.append(str(path))

if module_marker_hits != [module_path]:
    raise SystemExit('Module marker must appear only in new module. Hits: ' + ', '.join(module_marker_hits))

allowed_exact = {
    loader_path,
    module_path,
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
    print('REFUSE: changed files outside GoogleSync, loader, module, and focused smoke:')
    for item in bad:
        print(item)
    sys.exit(1)

print('loader_source=' + loader_path)
print('module_source=' + module_path)
print('PASS Stage 17K-Z-R6C split Profile GoogleSync module smoke')
PY
