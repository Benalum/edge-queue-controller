#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BX smoke: active source UI map inventory ==="
echo "MUTATION_SCOPE=read_only_active_source_map"
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
    ".git", ".cleanup-archive", ".cleanup-backups", ".cgpt-bridge",
    ".wrangler", ".cache", ".parcel-cache", ".next", "coverage",
    "cleanup", "docs", "ops", "__pycache__", "node_modules",
    ".venv", "venv", "dist", "build",
}
allowed_suffixes = {".py", ".js", ".ts", ".tsx", ".html", ".css", ".md", ".sh", ".json", ".jsonc"}

classes = {
    "controller_public_ui": re.compile(r"(login|register|profile|account|credits|system|admin|status|wrapper|public)", re.I),
    "cloudflare_gateway": re.compile(r"(cloudflare|gateway|proxy|worker|wrangler)", re.I),
    "study_ui_static": re.compile(r"(study|deck|card|review)", re.I),
    "companion_ui_static": re.compile(r"(companion|chat|queue|conversation)", re.I),
    "calendar_static": re.compile(r"(calendar|google|apple)", re.I),
    "protected_runtime": re.compile(r"(ct101|ollama|model|scheduler|worker|lane|warmup|job)", re.I),
}

counts = {key: 0 for key in classes}
top = {key: [] for key in classes}

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
    for key, pattern in classes.items():
        if pattern.search(rel) or pattern.search(text):
            counts[key] += 1
            if len(top[key]) < 8:
                top[key].append(rel)

print("ACTIVE_SOURCE_UI_MAP=completed")
for key, value in counts.items():
    print(f"{key}_files={value}")

for key, items in top.items():
    print()
    print(f"--- active UI map {key} files ---")
    for item in items:
        print(item)

if counts["controller_public_ui"] <= 0:
    raise SystemExit("FAIL: no active controller public UI candidates found")
if counts["cloudflare_gateway"] <= 0:
    raise SystemExit("FAIL: no active Cloudflare/gateway candidates found")

print()
print("PASS: controller-owned active source UI map inventory completed")
PY
