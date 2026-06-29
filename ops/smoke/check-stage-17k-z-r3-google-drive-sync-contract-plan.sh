#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r3-google-drive-sync-contract-plan.md"

echo "=== Stage 17K-Z-R3 Google Drive sync contract smoke ==="
echo "DOC=${DOC}"

test -f "$DOC"

python3 - <<'PY'
from pathlib import Path

doc = Path('docs/stage-17k-z-r3-google-drive-sync-contract-plan.md')
text = doc.read_text(encoding='utf-8')

required_markers = [
    'SAFETY_NON_ACTIVATION',
    'DATA_IN_DRIVE',
    'DRIVE_STORAGE_MODEL',
    'FOLDER_LAYOUT',
    'COMMON_SCHEMA_RULES',
    'SCHEMA_DECK',
    'SCHEMA_CARD',
    'SCHEMA_SESSION',
    'SCHEMA_STATS',
    'SCHEMA_HISTORY',
    'SYNC_DIRECTION',
    'CONFLICT_RULES',
    'PRIVACY_CONSENT',
    'OAUTH_SCOPES',
    'OFFLINE_LOCAL_FIRST',
    'END_SESSION_WRITEBACK',
    'ACCEPTANCE_CRITERIA_FOR_THIS_STAGE',
]

missing = [marker for marker in required_markers if marker not in text]
if missing:
    raise SystemExit('Missing required markers: ' + ', '.join(missing))

required_safety = [
    'No backend deploy.',
    'No frontend deploy.',
    'No database writes.',
    'No Google OAuth activation.',
    'No Google Drive writes.',
    'No model calls.',
    'No worker activation.',
    'No scheduler activation.',
    'No service restarts.',
]

missing_safety = [line for line in required_safety if line not in text]
if missing_safety:
    raise SystemExit('Missing safety lines: ' + ', '.join(missing_safety))

fence = chr(96) * 3
if fence in text:
    raise SystemExit('Doc must not contain Markdown code fences')

allowed = {
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.appdata',
}

scope_mentions = []
for raw in text.replace(',', ' ').split():
    cleaned = raw.strip().strip('.')
    if cleaned.startswith('https://www.googleapis.com/auth/drive'):
        scope_mentions.append(cleaned)

bad_scopes = [scope for scope in scope_mentions if scope not in allowed]
if bad_scopes:
    raise SystemExit('Unexpected Drive scope mentions: ' + ', '.join(sorted(set(bad_scopes))))

for forbidden in [
    'curl https://www.googleapis.com',
    'gcloud auth',
    'googleapis.com/drive/v3/files',
]:
    if forbidden in text:
        raise SystemExit('Doc contains forbidden activation/API text: ' + forbidden)

print('PASS Stage 17K-Z-R3 Google Drive sync contract doc smoke')
PY
