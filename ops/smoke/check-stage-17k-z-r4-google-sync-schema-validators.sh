#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 17K-Z-R4 GoogleSync local schema validator smoke ==="

test -d GoogleSync
test -d GoogleSync/schemas
test -d GoogleSync/validators
test -d GoogleSync/fixtures/valid
test -f GoogleSync/README.md
test -x GoogleSync/validators/validate_google_sync_schemas.py

python3 GoogleSync/validators/validate_google_sync_schemas.py

python3 - <<'PY'
from pathlib import Path
import subprocess
import sys

allowed_prefixes = (
    'GoogleSync/',
    'ops/smoke/check-stage-17k-z-r4-google-sync-schema-validators.sh',
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

for path in Path('GoogleSync').rglob('*'):
    if not path.is_file():
        continue
    text = path.read_text(encoding='utf-8')
    for forbidden in [
        'googleapis.com/drive/v3',
        'gapi.client',
        'gapi.auth',
        'oauth2.googleapis.com',
        'accounts.google.com',
        'curl https://www.googleapis.com',
    ]:
        if forbidden in text:
            raise SystemExit(f'Forbidden activation/API text in {path}: {forbidden}')

required_schema_names = {
    'manifest.schema.json',
    'deck.schema.json',
    'card.schema.json',
    'session.schema.json',
    'user_stats.schema.json',
    'deck_stats.schema.json',
    'history_event.schema.json',
    'conflict.schema.json',
    'outbox_entry.schema.json',
    'consent_event.schema.json',
}
actual_schema_names = {path.name for path in Path('GoogleSync/schemas').glob('*.schema.json')}
missing = sorted(required_schema_names - actual_schema_names)
if missing:
    raise SystemExit('Missing schema files: ' + ', '.join(missing))

print('PASS Stage 17K-Z-R4 GoogleSync smoke')
PY
