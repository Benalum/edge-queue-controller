#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BR reusable smoke: public/product surface static inventory ==="
echo "MUTATION_SCOPE=read_only_static_inventory"
echo "NO CT101 call"
echo "NO model/Ollama endpoint call"
echo "NO DB mutation"
echo "NO job mutation"
echo "NO runtime activation"

test -f edge_controller.py
python3 -m py_compile edge_controller.py
echo "PASS: edge_controller.py exists and compiles"

count_matches() {
  pattern="$1"
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
    --exclude-dir=dist \
    --exclude-dir=build \
    --exclude='*.sqlite3' \
    --exclude='*.db' \
    --include='*.py' \
    --include='*.js' \
    --include='*.ts' \
    --include='*.tsx' \
    --include='*.html' \
    --include='*.css' \
    --include='*.md' \
    --include='*.sh' \
    -E "$pattern" . 2>/dev/null | wc -l | tr -d ' '
}

print_top() {
  title="$1"
  pattern="$2"
  echo
  echo "=== top files: $title ==="
  grep -RIl \
    --exclude-dir=.git \
    --exclude-dir=.cleanup-archive \
    --exclude-dir=.cgpt-bridge \
    --exclude-dir=cleanup \
    --exclude-dir=.cleanup-archive \
    --exclude-dir=.cleanup-backups \
    --exclude-dir=__pycache__ \
    --exclude-dir=node_modules \
    --exclude-dir=.venv \
    --exclude-dir=venv \
    --exclude-dir=dist \
    --exclude-dir=build \
    --exclude='*.sqlite3' \
    --exclude='*.db' \
    --include='*.py' \
    --include='*.js' \
    --include='*.ts' \
    --include='*.tsx' \
    --include='*.html' \
    --include='*.css' \
    --include='*.md' \
    --include='*.sh' \
    -E "$pattern" . 2>/dev/null \
    | sed 's#^\./##' \
    | sort \
    | head -25 || true
}

study_files="$(count_matches 'study|Study')"
companion_files="$(count_matches 'companion|Companion')"
calendar_files="$(count_matches 'calendar|Calendar')"
credits_files="$(count_matches 'credit|credits|Credit|Credits')"
profile_account_files="$(count_matches 'profile|Profile|account|Account|login|Login|register|Register')"
admin_system_files="$(count_matches 'admin|Admin|system|System|health|status|Status')"
public_gateway_files="$(count_matches 'public|Public|gateway|Gateway|route|Route|proxy|Proxy')"
ui_files="$(count_matches 'html|css|frontend|wrapper|dashboard|page|button|card')"

printf 'study_files=%s\n' "$study_files"
printf 'companion_files=%s\n' "$companion_files"
printf 'calendar_files=%s\n' "$calendar_files"
printf 'credits_files=%s\n' "$credits_files"
printf 'profile_account_files=%s\n' "$profile_account_files"
printf 'admin_system_files=%s\n' "$admin_system_files"
printf 'public_gateway_files=%s\n' "$public_gateway_files"
printf 'ui_files=%s\n' "$ui_files"

print_top "Study" 'study|Study'
print_top "Companion" 'companion|Companion'
print_top "Calendar" 'calendar|Calendar'
print_top "Credits" 'credit|credits|Credit|Credits'
print_top "Profile Account Login" 'profile|Profile|account|Account|login|Login|register|Register'
print_top "Admin System Status" 'admin|Admin|system|System|health|status|Status'
print_top "Public Gateway Route Proxy" 'public|Public|gateway|Gateway|route|Route|proxy|Proxy'
print_top "UI Static" 'html|css|frontend|wrapper|dashboard|page|button|card'

total_surface_files="$((study_files + companion_files + calendar_files + credits_files + profile_account_files + admin_system_files + public_gateway_files + ui_files))"
printf 'total_surface_file_hits=%s\n' "$total_surface_files"

if [ "$total_surface_files" -le 0 ]; then
  echo "FAIL: no public/product/static surface files found"
  exit 1
fi

echo
echo "PASS: public/product surface static inventory completed"
