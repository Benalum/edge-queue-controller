#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

TOOL="ops/db/plan-companion-mock-backlog-cleanup-read-only.py"
DOC="docs/stage-16-fc-o45-e-ck-r-guarded-mock-companion-backlog-cleanup-plan.md"

test -f "$TOOL"
test -x "$TOOL"
test -f "$DOC"

grep -Fq "mode=ro" "$TOOL"
grep -Fq "companion.chat" "$TOOL"
grep -Fq "mock/no-model" "$TOOL"
grep -Fq "result_rows" "$TOOL"
grep -Fq "candidate_id_sha256" "$TOOL"
grep -Fq "requires_future_approval" "$TOOL"
grep -Fq "mutated" "$TOOL"

grep -Fq "Guarded Mock Companion Backlog Cleanup Plan" "$DOC"
grep -Fq "plan-companion-mock-backlog-cleanup-read-only.py" "$DOC"
grep -Fq "job_type=companion.chat" "$DOC"
grep -Fq "status=queued" "$DOC"
grep -Fq "attempts=0" "$DOC"
grep -Fq "result_rows=0" "$DOC"
grep -Fq "requested_model=mock/no-model" "$DOC"
grep -Fq "440 eligible queued" "$DOC"
grep -Fq "437 say_hello_one_sentence" "$DOC"
grep -Fq "opens SQLite using" "$DOC"
grep -Fq "does not update jobs" "$DOC"
grep -Fq "does not insert job results" "$DOC"
grep -Fq "does not call PVESO/Ollama/model endpoints" "$DOC"
grep -Fq "Future cleanup policy" "$DOC"
grep -Fq "Create a DB backup" "$DOC"
grep -Fq "Prefer an exclusion policy" "$DOC"
grep -Fq "Run CK-S" "$DOC"

python3 -m py_compile "$TOOL"

python3 - <<'PY'
import json
import sqlite3
import subprocess
import tempfile
from pathlib import Path

tool = Path("ops/db/plan-companion-mock-backlog-cleanup-read-only.py").resolve()

with tempfile.TemporaryDirectory() as td:
    db = Path(td) / "queue.sqlite3"

    conn = sqlite3.connect(db)
    try:
        conn.executescript(
            """
            CREATE TABLE jobs (
                id INTEGER PRIMARY KEY,
                job_type TEXT,
                prompt TEXT,
                requested_model TEXT,
                status TEXT,
                attempts INTEGER,
                created_at TEXT,
                updated_at TEXT
            );
            CREATE TABLE job_results (
                job_id INTEGER,
                model TEXT,
                response_text TEXT
            );

            INSERT INTO jobs VALUES
              (1, 'companion.chat', 'Say hello in 1 sentence to me.', 'mock/no-model', 'queued', 0, '2026-06-25T01:14:17Z', '2026-06-25T01:14:17Z'),
              (2, 'companion.chat', 'stage15e-authenticated-mock-queued-chat-validation-2026-06-20T0448Z', 'mock/no-model', 'queued', 0, '2026-06-20T05:02:17Z', '2026-06-20T05:02:17Z'),
              (3, 'companion.chat', 'real model should not match', 'qwen2.5:0.5b', 'queued', 0, '2026-06-25T00:00:00Z', '2026-06-25T00:00:00Z'),
              (4, 'companion.chat', 'attempted should not match', 'mock/no-model', 'queued', 1, '2026-06-25T00:00:00Z', '2026-06-25T00:00:00Z'),
              (5, 'study.flashcards', 'wrong type', 'mock/no-model', 'queued', 0, '2026-06-25T00:00:00Z', '2026-06-25T00:00:00Z'),
              (6, 'companion.chat', 'has result should not match', 'mock/no-model', 'queued', 0, '2026-06-25T00:00:00Z', '2026-06-25T00:00:00Z');

            INSERT INTO job_results VALUES (6, 'mock/no-model', 'done');
            """
        )
        conn.commit()
    finally:
        conn.close()

    text = subprocess.run(
        [str(tool), "--db", str(db), "--expected-count", "2", "--limit", "5"],
        text=True,
        capture_output=True,
        check=True,
    ).stdout
    assert "mock_companion_cleanup_plan_read_only=yes" in text, text
    assert "candidate_count=2" in text, text
    assert "candidate_min_id=1" in text, text
    assert "candidate_max_id=2" in text, text
    assert "candidate_prompt_bucket bucket=say_hello_one_sentence count=1" in text, text
    assert "candidate_prompt_bucket bucket=stage15e_mock_validation count=1" in text, text
    assert "mutated=no" in text, text
    assert "mock_companion_cleanup_plan_done=yes" in text, text

    raw = subprocess.run(
        [str(tool), "--db", str(db), "--expected-count", "2", "--json"],
        text=True,
        capture_output=True,
        check=True,
    ).stdout
    payload = json.loads(raw)
    assert payload["ok"] is True, payload
    assert payload["mode"] == "read_only", payload
    assert payload["candidate_count"] == 2, payload
    assert payload["candidate_min_id"] == 1, payload
    assert payload["candidate_max_id"] == 2, payload
    assert payload["candidate_criteria"]["requested_model"] == "mock/no-model", payload
    assert payload["mutated"] is False, payload

print("guarded_mock_companion_cleanup_dry_run_tool_offline_smoke_ok=yes")
PY

echo "PASS stage-16-fc-o45-e-ck-r guarded cleanup dry-run tool smoke"
