#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 17K-Z-R6 profile-only GoogleSync login UI smoke ==="

SOURCE_PATH_FILE="GoogleSync/contracts/stage-17k-z-r6-profile-ui-source-path.txt"
CONTRACT="GoogleSync/contracts/stage-17k-z-r6-profile-only-google-sync-login-ui.md"

test -f "$SOURCE_PATH_FILE"
test -f "$CONTRACT"
test -x GoogleSync/validators/validate_google_sync_schemas.py
test -x GoogleSync/validators/validate_indexeddb_outbox_contract.py

python3 GoogleSync/validators/validate_google_sync_schemas.py
python3 GoogleSync/validators/validate_indexeddb_outbox_contract.py

python3 - <<'PY'
from pathlib import Path
import subprocess
import sys

marker = 'APC_GOOGLE_SYNC_PROFILE_ONLY_MARKER_STAGE_17K_Z_R6'
start = '/* APC_GOOGLE_SYNC_PROFILE_ONLY_STAGE_17K_Z_R6_START */'
end = '/* APC_GOOGLE_SYNC_PROFILE_ONLY_STAGE_17K_Z_R6_END */'
source_path = Path('GoogleSync/contracts/stage-17k-z-r6-profile-ui-source-path.txt').read_text(encoding='utf-8').strip()
selected = Path(source_path)
if not selected.exists():
    raise SystemExit('Recorded source path does not exist: ' + source_path)
source_l = source_path.lower()
if 'profile' not in source_l and 'privatepages' not in source_l and not source_l.endswith('app.js') and not source_l.endswith('index.html'):
    raise SystemExit('Recorded source is not Profile/privatepages-capable: ' + source_path)
text = selected.read_text(encoding='utf-8')
if marker not in text:
    raise SystemExit('Selected source missing R6 marker')
if start not in text or end not in text:
    raise SystemExit('Selected source missing R6 block delimiters')
block = text.split(start, 1)[1].split(end, 1)[0]
required_ui = [
    'Google Drive sync',
    'Not connected',
    'Connect Google Drive',
    'Sync now',
    'data-apc-google-sync-profile-panel',
    'data-apc-google-sync-profile-only',
    'data-apc-google-sync-oauth-active',
    'data-apc-google-sync-drive-reads',
    'data-apc-google-sync-drive-writes',
    'isProfileSurface',
]
missing = [item for item in required_ui if item not in block]
if missing:
    raise SystemExit('UI block missing required text/markers: ' + ', '.join(missing))
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
        raise SystemExit('Forbidden activation/API/navigation text in UI block: ' + forbidden)

matches = []
for base in [Path('frontend'), Path('public'), Path('src')]:
    if not base.exists():
        continue
    for path in base.rglob('*'):
        if not path.is_file():
            continue
        if any(part in {'.git', 'node_modules', 'dist', 'build'} for part in path.parts):
            continue
        if path.suffix.lower() not in {'.js', '.html', '.css', '.ts', '.tsx', '.jsx'}:
            continue
        try:
            candidate_text = path.read_text(encoding='utf-8')
        except UnicodeDecodeError:
            continue
        if marker in candidate_text:
            matches.append(str(path))

if matches != [source_path]:
    raise SystemExit('Marker must appear only in selected source. Matches: ' + ', '.join(matches))

bad_page_hits = [path for path in matches if any(fragment in path.lower() for fragment in ['/study/', '\\study\\', '/companion/', '\\companion\\', '/admin/', '\\admin\\'])]
if bad_page_hits:
    raise SystemExit('Marker appeared in page-specific non-Profile source: ' + ', '.join(bad_page_hits))

allowed_prefixes = (
    'GoogleSync/',
    'ops/smoke/check-stage-17k-z-r6-profile-only-google-sync-login-ui.sh',
)
out = subprocess.check_output(['git', 'status', '--porcelain'], text=True)
bad = []
for line in out.splitlines():
    path = line[3:]
    if ' -> ' in path:
        bad.append(line)
    elif path == source_path:
        continue
    elif path.startswith(allowed_prefixes):
        continue
    else:
        bad.append(line)
if bad:
    print('REFUSE: changed files outside GoogleSync, focused smoke, and selected source:')
    for item in bad:
        print(item)
    sys.exit(1)

print('selected_source=' + source_path)
print('PASS Stage 17K-Z-R6 profile-only GoogleSync login UI smoke')
PY
