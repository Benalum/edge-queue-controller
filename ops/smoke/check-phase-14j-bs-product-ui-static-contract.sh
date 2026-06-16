#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BS reusable smoke: product UI static contract ==="
echo "MUTATION_SCOPE=read_only_static_contract"
echo "NO CT101 call"
echo "NO model/Ollama endpoint call"
echo "NO DB mutation"
echo "NO job mutation"
echo "NO runtime activation"

test -f edge_controller.py
python3 -m py_compile edge_controller.py
echo "PASS: edge_controller.py compiles"

study_hits="$(grep -RIn --exclude-dir=.git --exclude-dir=.cgpt-bridge --exclude-dir=cleanup --exclude-dir=.cleanup-archive --exclude-dir=.cleanup-backups --exclude='*.sqlite3' --exclude='*.db' -E 'Study|study' . 2>/dev/null | wc -l | tr -d ' ')"
companion_hits="$(grep -RIn --exclude-dir=.git --exclude-dir=.cgpt-bridge --exclude-dir=cleanup --exclude-dir=.cleanup-archive --exclude-dir=.cleanup-backups --exclude='*.sqlite3' --exclude='*.db' -E 'Companion|companion' . 2>/dev/null | wc -l | tr -d ' ')"
profile_hits="$(grep -RIn --exclude-dir=.git --exclude-dir=.cgpt-bridge --exclude-dir=cleanup --exclude-dir=.cleanup-archive --exclude-dir=.cleanup-backups --exclude='*.sqlite3' --exclude='*.db' -E 'Profile|profile|Account|account|login|Login|register|Register' . 2>/dev/null | wc -l | tr -d ' ')"
system_hits="$(grep -RIn --exclude-dir=.git --exclude-dir=.cgpt-bridge --exclude-dir=cleanup --exclude-dir=.cleanup-archive --exclude-dir=.cleanup-backups --exclude='*.sqlite3' --exclude='*.db' -E 'System|system|Admin|admin|health|status|Status' . 2>/dev/null | wc -l | tr -d ' ')"
calendar_hits="$(grep -RIn --exclude-dir=.git --exclude-dir=.cgpt-bridge --exclude-dir=cleanup --exclude-dir=.cleanup-archive --exclude-dir=.cleanup-backups --exclude='*.sqlite3' --exclude='*.db' -E 'Calendar|calendar|Google Calendar|Apple Calendar' . 2>/dev/null | wc -l | tr -d ' ')"
credits_hits="$(grep -RIn --exclude-dir=.git --exclude-dir=.cgpt-bridge --exclude-dir=cleanup --exclude-dir=.cleanup-archive --exclude-dir=.cleanup-backups --exclude='*.sqlite3' --exclude='*.db' -E 'Credits|credits|credit|reward|Reward|ads|Ads' . 2>/dev/null | wc -l | tr -d ' ')"

printf 'study_hits=%s\n' "$study_hits"
printf 'companion_hits=%s\n' "$companion_hits"
printf 'profile_hits=%s\n' "$profile_hits"
printf 'system_hits=%s\n' "$system_hits"
printf 'calendar_hits=%s\n' "$calendar_hits"
printf 'credits_hits=%s\n' "$credits_hits"

if [ "$study_hits" -le 0 ]; then echo "FAIL: Study surface markers missing"; exit 1; fi
if [ "$companion_hits" -le 0 ]; then echo "FAIL: Companion surface markers missing"; exit 1; fi
if [ "$profile_hits" -le 0 ]; then echo "FAIL: Profile/Account surface markers missing"; exit 1; fi
if [ "$system_hits" -le 0 ]; then echo "FAIL: System/Admin surface markers missing"; exit 1; fi

echo
echo "=== top product UI/static files ==="
grep -RIl \
  --exclude-dir=.git \
    --exclude-dir=.cgpt-bridge \
    --exclude-dir=cleanup \
    --exclude-dir=.cleanup-archive \
    --exclude-dir=.cleanup-backups \
  --exclude-dir=__pycache__ \
  --exclude-dir=node_modules \
  --exclude-dir=.venv \
  --exclude-dir=venv \
  --exclude='*.sqlite3' \
  --exclude='*.db' \
  --include='*.py' \
  --include='*.js' \
  --include='*.ts' \
  --include='*.tsx' \
  --include='*.html' \
  --include='*.css' \
  --include='*.md' \
  -E 'Study|study|Companion|companion|Profile|profile|Account|account|Calendar|calendar|Credits|credits|System|system|Admin|admin' . 2>/dev/null \
  | sed 's#^\./##' \
  | sort \
  | head -80 || true

echo
echo "PASS: product UI static contract completed"
