#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 17K-Z-R6B Profile GoogleSync source placement verification smoke ==="

SOURCE_PATH_FILE="GoogleSync/contracts/stage-17k-z-r6-profile-ui-source-path.txt"
DOC="GoogleSync/contracts/stage-17k-z-r6b-profile-source-placement-verification.md"
REPORT="GoogleSync/contracts/stage-17k-z-r6b-profile-source-placement-verification.apc.json"

test -f "$SOURCE_PATH_FILE"
test -f "$DOC"
test -f "$REPORT"
test -x GoogleSync/validators/validate_google_sync_schemas.py
test -x GoogleSync/validators/validate_indexeddb_outbox_contract.py

python3 GoogleSync/validators/validate_google_sync_schemas.py
python3 GoogleSync/validators/validate_indexeddb_outbox_contract.py

python3 - <<'PY'
from pathlib import Path
import json
import subprocess
import sys

marker = 'APC_GOOGLE_SYNC_PROFILE_ONLY_MARKER_STAGE_17K_Z_R6'
start = '/* APC_GOOGLE_SYNC_PROFILE_ONLY_STAGE_17K_Z_R6_START */'
end = '/* APC_GOOGLE_SYNC_PROFILE_ONLY_STAGE_17K_Z_R6_END */'
source_path = Path('GoogleSync/contracts/stage-17k-z-r6-profile-ui-source-path.txt').read_text(encoding='utf-8').strip()
selected = Path(source_path)
report = json.loads(Path('GoogleSync/contracts/stage-17k-z-r6b-profile-source-placement-verification.apc.json').read_text(encoding='utf-8'))

if report.get('stage') != '17K-Z-R6B':
    raise SystemExit('Report stage mismatch')
if report.get('selected_source') != source_path:
    raise SystemExit('Report selected source mismatch')
if not selected.exists():
    raise SystemExit('Selected source missing: ' + source_path)

text = selected.read_text(encoding='utf-8')
if marker not in text:
    raise SystemExit('Selected source missing R6 marker')
if start not in text or end not in text:
    raise SystemExit('Selected source missing R6 delimiters')
block = text.split(start, 1)[1].split(end, 1)[0]

required_block_items = [
    'isProfileSurface',
    'data-apc-google-sync-profile-only',
    'data-apc-google-sync-oauth-active',
    'data-apc-google-sync-drive-reads',
    'data-apc-google-sync-drive-writes',
    'Connect Google Drive',
    'Sync now',
    'disabled',
]
missing = [item for item in required_block_items if item not in block]
if missing:
    raise SystemExit('R6 block missing required items: ' + ', '.join(missing))

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
    if forbidden in block:
        raise SystemExit('Forbidden activation text in R6 block: ' + forbidden)

marker_hits = []
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
            candidate_text = path.read_text(encoding='utf-8')
        except UnicodeDecodeError:
            continue
        if marker in candidate_text:
            marker_hits.append(str(path))

if marker_hits != [source_path]:
    raise SystemExit('Marker must appear only in selected source. Hits: ' + ', '.join(marker_hits))

if report.get('fetch_present_in_block') is not False:
    raise SystemExit('Report says fetch is present in block')
if report.get('navigation_present_in_block') is not False:
    raise SystemExit('Report says navigation is present in block')
if report.get('recommendation') not in {'keep_current_source', 'acceptable_temporarily_then_split_before_oauth', 'split_before_oauth'}:
    raise SystemExit('Unexpected placement recommendation')

allowed_prefixes = (
    'GoogleSync/',
    'ops/smoke/check-stage-17k-z-r6b-profile-source-placement-verification.sh',
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

print('selected_source=' + source_path)
print('placement_recommendation=' + report.get('recommendation'))
print('PASS Stage 17K-Z-R6B Profile GoogleSync source placement verification smoke')
PY
