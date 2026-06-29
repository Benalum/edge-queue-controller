#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 17K-Z-R7B Google OAuth client ID injection contract smoke ==="

MODULE_PATH_FILE="GoogleSync/contracts/stage-17k-z-r6c-profile-google-sync-module-source-path.txt"
CONTRACT_JSON="GoogleSync/contracts/stage-17k-z-r7b-google-oauth-client-id-injection-contract.apc.json"
CONTRACT_MD="GoogleSync/contracts/stage-17k-z-r7b-google-oauth-client-id-injection-contract.md"
EXAMPLE_CONFIG="GoogleSync/config/google-sync-client-id.example.js"

test -f "$MODULE_PATH_FILE"
test -f "$CONTRACT_JSON"
test -f "$CONTRACT_MD"
test -f "$EXAMPLE_CONFIG"
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
    raise SystemExit('Profile GoogleSync module missing: ' + module_path)
text = module.read_text(encoding='utf-8')

required_module = [
    'APC_GOOGLE_SYNC_PROFILE_OAUTH_DRIVE_DEV_PROOF_STAGE_17K_Z_R7',
    'window.APC_GOOGLE_SYNC_CONFIG',
    'googleClientId',
    'meta[name="apc-google-client-id"]',
    'https://www.googleapis.com/auth/drive.file',
]
missing = [item for item in required_module if item not in text]
if missing:
    raise SystemExit('R7 module missing client ID injection hooks: ' + ', '.join(missing))

scope_literals = re.findall(r'https://www[.]googleapis[.]com/auth/drive(?:[.][A-Za-z0-9_]+)?', text)
bad_scopes = sorted(set(scope for scope in scope_literals if scope != 'https://www.googleapis.com/auth/drive.file'))
if bad_scopes:
    raise SystemExit('Unexpected Drive scope in module: ' + ', '.join(bad_scopes))

contract = json.loads(Path('GoogleSync/contracts/stage-17k-z-r7b-google-oauth-client-id-injection-contract.apc.json').read_text(encoding='utf-8'))
checks = {
    'stage': contract.get('stage') == '17K-Z-R7B',
    'real_client_id_committed': contract.get('real_client_id_committed') is False,
    'oauth_executed_in_this_stage': contract.get('oauth_executed_in_this_stage') is False,
    'drive_reads_in_this_stage': contract.get('drive_reads_in_this_stage') is False,
    'drive_writes_in_this_stage': contract.get('drive_writes_in_this_stage') is False,
    'scope': contract.get('scope') == 'https://www.googleapis.com/auth/drive.file',
}
failed = [key for key, ok in checks.items() if not ok]
if failed:
    raise SystemExit('Contract checks failed: ' + ', '.join(failed))

recommended = contract.get('recommended_deploy_injection', {})
if recommended.get('method') != 'runtime_generated_config_script':
    raise SystemExit('Expected runtime_generated_config_script deploy method')
if recommended.get('git_commit_real_client_id') is not False:
    raise SystemExit('Contract must forbid committing real client ID')

example = Path('GoogleSync/config/google-sync-client-id.example.js').read_text(encoding='utf-8')
if 'REPLACE_WITH_WEB_OAUTH_CLIENT_ID.apps.googleusercontent.com' not in example:
    raise SystemExit('Example config missing placeholder client ID')

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
    raise SystemExit('Real-looking Google OAuth client ID committed: ' + '; '.join(hits))

allowed_prefixes = (
    'GoogleSync/',
    'ops/smoke/check-stage-17k-z-r7b-google-oauth-client-id-injection-contract.sh',
)
out = subprocess.check_output(['git', 'status', '--porcelain'], text=True)
bad = []
for line in out.splitlines():
    path = line[3:]
    if ' -> ' in path:
        bad.append(line)
    elif path.startswith(allowed_prefixes):
        continue
    else:
        bad.append(line)
if bad:
    print('REFUSE: changed files outside GoogleSync and focused smoke:')
    for item in bad:
        print(item)
    sys.exit(1)

print('module_source=' + module_path)
print('scope=https://www.googleapis.com/auth/drive.file')
print('client_id_injection=runtime_generated_config_script')
print('PASS Stage 17K-Z-R7B Google OAuth client ID injection contract smoke')
PY
