#!/usr/bin/env bash

create_stage5p_pack_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  out_dir="$HOME/Desktop/ai-platform-stage5p-inspection-pack"
  stamp="$(date +%Y%m%d-%H%M%S)"
  pack_dir="$out_dir/ai-platform-stage5p-inspection-$stamp"
  zip_file="$out_dir/ai-platform-stage5p-inspection-$stamp.zip"

  mkdir -p "$pack_dir"

  echo "=== checkpoint ==="
  git status --short
  git rev-parse --short HEAD
  git tag --points-at HEAD || true

  echo
  echo "=== create inspection report ==="
  cat > "$pack_dir/README-STAGE5P-INSPECTION.txt" <<EOF
AI Platform Control — Stage 5P inspection pack

Goal:
Inspect existing Study session, Companion queue, intent routing, model routing, queue worker, and old/dead experimental code before building the new Study Session + Model Router foundation.

Current known checkpoint:
$(git rev-parse --short HEAD)
$(git tag --points-at HEAD || true)

Important project constraints:
- Do not add a local calendar database.
- Calendar must remain provider-backed only: Google Calendar / Apple Calendar later.
- Keep logged-out public summaries working.
- Keep auth/header behavior unchanged.
- Keep queued chat behavior unless intentionally changing it.
- Use safe bash scripts that do not use exit.
- Prefer stage-by-stage commits and tags.
EOF

  echo
  echo "=== generate code inventory ==="
  {
    echo "# Stage 5P Existing Code Inventory"
    echo
    echo "## Git checkpoint"
    git status --short
    git rev-parse --short HEAD
    git tag --points-at HEAD || true

    echo
    echo "## Files likely related to Study / Companion / Queue / Router / Intent / Model"
    find . \
      -path './.git' -prune -o \
      -path './.venv' -prune -o \
      -path './venv' -prune -o \
      -path './node_modules' -prune -o \
      -path './__pycache__' -prune -o \
      -type f \
      | sed 's#^\./##' \
      | grep -Ei 'study|companion|queue|queued|chat|intent|router|route|model|ollama|worker|session|deck|card|scheduler|admin|system' \
      | sort

    echo
    echo "## Important grep hits"
    for pattern in \
      "study session" \
      "study_session" \
      "session" \
      "pause" \
      "resume" \
      "correct" \
      "incorrect" \
      "skip" \
      "read answer" \
      "answer" \
      "intent" \
      "router" \
      "model_tier" \
      "model tier" \
      "ollama" \
      "queued" \
      "/api/chat/queued" \
      "job_id" \
      "worker" \
      "deck" \
      "card"; do
      echo
      echo "### grep: $pattern"
      grep -RIn --exclude-dir=.git --exclude-dir=.venv --exclude-dir=venv --exclude-dir=node_modules --exclude-dir=__pycache__ \
        --exclude='*.sqlite3' --exclude='*.db' --exclude='*.log' --exclude='*.bak*' \
        "$pattern" . | sed -n '1,160p' || true
    done

    echo
    echo "## app.js function names likely relevant"
    python3 - <<'PY'
from pathlib import Path
import re

p = Path("frontend/wrapper-ui/app.js")
if not p.exists():
    print("frontend/wrapper-ui/app.js missing")
    raise SystemExit

s = p.read_text(errors="replace")
rxs = [
    r"function\s+([A-Za-z0-9_$]*(?:Study|study|Companion|companion|Queued|queued|Chat|chat|Intent|intent|Router|router|Model|model|Session|session|Deck|deck|Card|card)[A-Za-z0-9_$]*)\s*\(",
    r"(?:const|let|var)\s+([A-Za-z0-9_$]*(?:Study|study|Companion|companion|Queued|queued|Chat|chat|Intent|intent|Router|router|Model|model|Session|session|Deck|deck|Card|card)[A-Za-z0-9_$]*)\s*=",
]
found = []
for rx in rxs:
    for m in re.finditer(rx, s):
        line = s.count("\n", 0, m.start()) + 1
        item = (line, m.group(1))
        if item not in found:
            found.append(item)
for line, name in sorted(found):
    print(f"{line}: {name}")
PY

    echo
    echo "## edge_controller.py route/function names likely relevant"
    python3 - <<'PY'
from pathlib import Path
import re

p = Path("edge_controller.py")
if not p.exists():
    print("edge_controller.py missing")
    raise SystemExit

s = p.read_text(errors="replace")
for m in re.finditer(r"^def\s+([A-Za-z0-9_]+)\s*\(", s, re.M):
    name = m.group(1)
    if re.search(r"study|companion|queue|queued|chat|intent|router|model|ollama|worker|session|deck|card|admin|system", name, re.I):
        line = s.count("\n", 0, m.start()) + 1
        print(f"{line}: def {name}")
PY
  } > "$pack_dir/stage5p-existing-code-inventory.md"

  echo
  echo "=== copy selected project files ==="
  mkdir -p "$pack_dir/repo"

  rsync -a \
    --exclude='.git/' \
    --exclude='.venv/' \
    --exclude='venv/' \
    --exclude='node_modules/' \
    --exclude='__pycache__/' \
    --exclude='.pytest_cache/' \
    --exclude='.mypy_cache/' \
    --exclude='*.pyc' \
    --exclude='*.pyo' \
    --exclude='*.sqlite3' \
    --exclude='*.sqlite' \
    --exclude='*.db' \
    --exclude='*.db-*' \
    --exclude='*.log' \
    --exclude='*.bak' \
    --exclude='*.bak-*' \
    --exclude='*.bak-*/*' \
    --exclude='*.tar' \
    --exclude='*.tar.gz' \
    --exclude='*.zip' \
    --exclude='.env' \
    --exclude='.env.*' \
    --exclude='secrets*' \
    --exclude='*_secret*' \
    --exclude='*token*' \
    --exclude='*credential*' \
    ./ "$pack_dir/repo/"

  echo
  echo "=== create zip ==="
  cd "$out_dir" || return 1
  zip -qr "$zip_file" "$(basename "$pack_dir")"

  echo
  echo "=== pack created ==="
  ls -lh "$zip_file"
  echo "$zip_file"

  echo
  echo "=== final repo checkpoint ==="
  cd "$HOME/Desktop/edge-queue-controller" || return 1
  git status --short
  git rev-parse --short HEAD
  git tag --points-at HEAD || true

  return 0
}

create_stage5p_pack_main "$@"
return 0 2>/dev/null || true
