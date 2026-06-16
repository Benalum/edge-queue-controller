#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BW smoke: active source-only UI/route inventory ==="
echo "MUTATION_SCOPE=read_only_active_source_static_inventory"
echo "NO CT101 call"
echo "NO model/Ollama endpoint call"
echo "NO DB mutation"
echo "NO job mutation"
echo "NO service restart/reload"
echo "NO scheduler activation"
echo "NO worker activation"
echo "NO runtime activation"

python3 -m py_compile edge_controller.py

python3 - <<'PY'
from pathlib import Path
import re

skip_parts = {
    ".git",
    ".cleanup-archive",
    ".cleanup-backups",
    ".cgpt-bridge",
    "cleanup",
    "docs",
    "ops",
    "__pycache__",
    "node_modules",
    ".venv",
    "venv",
    "dist",
    "build",
}
allowed_suffixes = {".py", ".js", ".ts", ".tsx", ".html", ".css", ".md", ".sh", ".json", ".jsonc"}

patterns = {
    "controller_owned_routes": re.compile(r"(/api/auth|/api/account|/api/credits|/api/system|/api/jobs|/profile|/login|/register|credits|account|profile|system|admin)", re.I),
    "product_surfaces": re.compile(r"(study|companion|calendar|profile|account|credits|admin|system)", re.I),
    "ui_static": re.compile(r"(html|css|template|button|card|page|wrapper|dashboard|nav|header|footer)", re.I),
    "gateway_proxy": re.compile(r"(gateway|proxy|cloudflare|route|worker)", re.I),
    "runtime_sensitive": re.compile(r"(ollama|model|ct101|scheduler|worker|lane|warmup)", re.I),
}

counts = {key: 0 for key in patterns}
top = {key: [] for key in patterns}

for path in sorted(Path(".").rglob("*")):
    if not path.is_file():
        continue
    if any(part in skip_parts for part in path.parts):
        continue
    if path.suffix not in allowed_suffixes:
        continue

    rel = str(path).removeprefix("./")
    try:
        text = path.read_text(errors="ignore")
    except Exception:
        continue

    for key, pattern in patterns.items():
        if pattern.search(rel) or pattern.search(text):
            counts[key] += 1
            if len(top[key]) < 15:
                top[key].append(rel)

print("ACTIVE_SOURCE_ONLY_INVENTORY=completed")
for key, value in counts.items():
    print(f"{key}_files={value}")

for key, items in top.items():
    print()
    print(f"--- active source top {key} files ---")
    for item in items:
        print(item)

if counts["controller_owned_routes"] <= 0:
    raise SystemExit("FAIL: no active source controller-owned route candidates found")
if counts["product_surfaces"] <= 0:
    raise SystemExit("FAIL: no active source product surface candidates found")
if counts["ui_static"] <= 0:
    raise SystemExit("FAIL: no active source UI/static candidates found")

print()
print("PASS: active source-only UI/route inventory completed")
PY
