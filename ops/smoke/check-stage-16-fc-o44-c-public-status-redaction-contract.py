#!/usr/bin/env python3
import ast
import re
from pathlib import Path

SOURCE = Path("edge_controller.py")
text = SOURCE.read_text()

start = text.index('@app.get("/system/status")')
m = re.search(r'\n@app\.', text[start + 1:])
assert m, "next route missing"
block = text[start:start + 1 + m.start()]

for required in [
    "APC_PUBLIC_STATUS_REDACTION_FC_O44_C",
    "async def public_system_status",
    '"Study API"',
    '"Companion API"',
    '"Profile API"',
    '"Calendar Integrations"',
    '"Images API"',
]:
    assert required in block, f"missing required marker: {required}"

forbidden_patterns = [
    r"127\.0\.0\.1",
    r"localhost",
    r"local-health",
    r"/system/local-health",
    r"http://[^\"']*:[0-9]+",
    r"https://[^\"']*:[0-9]+",
    r"CT203",
    r"ct-203",
    r"CT204",
    r"ct-204",
    r"CT101",
    r"ct-101",
    r"VM200",
    r"vm-200",
    r"PVEW",
    r"PVESO",
    r"Proxmox",
    r"nginx",
    r"cloudflared",
    r"/srv/",
    r"admin_model_warmup",
    r"model_memory_status",
    r"warmup",
    r"Ollama",
    r"qwen",
    r"llama",
    r"edge-queue-controller",
    r"controller/API",
    r"queue/API",
    r"worker dispatch",
    r"manual-unlock",
    r"mountpoint",
    r"private_storage",
    r"private_storage_status",
]
for pattern in forbidden_patterns:
    assert not re.search(pattern, block, re.I), f"forbidden term in public route block: {pattern}"

tree = ast.parse(text)
func = None
for node in tree.body:
    if isinstance(node, ast.AsyncFunctionDef) and node.name == "public_system_status":
        func = node
        break
assert func is not None, "public_system_status function missing"

print("stage-16-fc-o44-c public status redaction contract smoke passed")
