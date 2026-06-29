#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 17K-Z-R5 GoogleSync IndexedDB outbox contract smoke ==="

test -d GoogleSync
test -d GoogleSync/contracts
test -f GoogleSync/contracts/stage-17k-z-r5-indexeddb-outbox-contract.md
test -f GoogleSync/contracts/indexeddb-outbox-contract.apc.json
test -f GoogleSync/fixtures/valid/indexeddb_outbox_entry.r5.valid.json
test -x GoogleSync/validators/validate_indexeddb_outbox_contract.py
test -x GoogleSync/validators/validate_google_sync_schemas.py

python3 GoogleSync/validators/validate_google_sync_schemas.py
python3 GoogleSync/validators/validate_indexeddb_outbox_contract.py

python3 - <<'PY'
from pathlib import Path
import json
import subprocess
import sys

allowed_prefixes = (
    'GoogleSync/',
    'ops/smoke/check-stage-17k-z-r5-google-sync-indexeddb-outbox-contract.sh',
)

out = subprocess.check_output(['git', 'status', '--porcelain'], text=True)
bad = []
for line in out.splitlines():
    path = line[3:]
    if ' -> ' in path:
        bad.append(line)
    elif not path.startswith(allowed_prefixes):
        bad.append(line)

if bad:
    print('REFUSE: changed files outside GoogleSync folder and focused smoke:')
    for item in bad:
        print(item)
    sys.exit(1)

contract = json.loads(Path('GoogleSync/contracts/indexeddb-outbox-contract.apc.json').read_text(encoding='utf-8'))
store_names = {store['name'] for store in contract['stores']}
for required in [
    'google_sync_outbox',
    'google_sync_history_pending',
    'google_sync_sessions_pending',
    'google_sync_stats_pending',
    'google_sync_consent_audit',
]:
    if required not in store_names:
        raise SystemExit('Missing required store: ' + required)

if contract['execution_rules']['r5_runtime_implementation'] is not False:
    raise SystemExit('R5 must not implement runtime sync')

if contract['database']['no_oauth_activation'] is not True:
    raise SystemExit('R5 must not activate OAuth')

if contract['database']['no_drive_write'] is not True:
    raise SystemExit('R5 must not write to Drive')

print('PASS Stage 17K-Z-R5 GoogleSync smoke')
PY
