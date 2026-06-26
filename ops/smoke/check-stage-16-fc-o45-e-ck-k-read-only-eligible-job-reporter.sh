#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

REPORTER="ops/workers/list-eligible-deterministic-companion-jobs.sh"
DOC="docs/stage-16-fc-o45-e-ck-k-read-only-eligible-companion-job-reporter.md"

test -f "$REPORTER"
test -x "$REPORTER"
test -f "$DOC"

grep -Fq "list-eligible-deterministic-companion-jobs.sh" "$REPORTER"
grep -Fq -- "--expected-marker" "$REPORTER"
grep -Fq -- "--json" "$REPORTER"
grep -Fq "mode=ro" "$REPORTER"
grep -Fq "j.job_type = 'companion.chat'" "$REPORTER"
grep -Fq "j.status = 'queued'" "$REPORTER"
grep -Fq "COALESCE(j.attempts, 0) = 0" "$REPORTER"
grep -Fq "COALESCE(r.result_rows, 0) = 0" "$REPORTER"
grep -Fq "eligible_companion_jobs_read_only=yes" "$REPORTER"
grep -Fq "eligible_companion_jobs_report_done=yes" "$REPORTER"

grep -Fq "Read-Only Eligible Companion Job Reporter" "$DOC"
grep -Fq "ops/workers/list-eligible-deterministic-companion-jobs.sh" "$DOC"
grep -Fq "job_type=companion.chat" "$DOC"
grep -Fq "status=queued" "$DOC"
grep -Fq "attempts=0" "$DOC"
grep -Fq "result_rows=0" "$DOC"
grep -Fq "opens SQLite in read-only mode" "$DOC"
grep -Fq "does not insert jobs" "$DOC"
grep -Fq "does not mutate jobs" "$DOC"
grep -Fq "does not insert results" "$DOC"
grep -Fq "does not start services" "$DOC"
grep -Fq "does not call the selector wrapper" "$DOC"
grep -Fq "does not call PVESO, Ollama, or any model endpoint" "$DOC"

bash -n "$REPORTER"

python3 - <<'PY'
import json
import sqlite3
import subprocess
import tempfile
from pathlib import Path

reporter = Path("ops/workers/list-eligible-deterministic-companion-jobs.sh").resolve()

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

            INSERT INTO jobs VALUES (
                201,
                'companion.chat',
                'Please answer exactly: FC-O45-E-CK-K-UNIT-A',
                'qwen2.5:0.5b',
                'queued',
                0,
                '2026-06-26T00:00:00Z',
                '2026-06-26T00:00:00Z'
            );

            INSERT INTO jobs VALUES (
                202,
                'companion.chat',
                'Please answer exactly: FC-O45-E-CK-K-UNIT-B',
                'qwen2.5:0.5b',
                'queued',
                0,
                '2026-06-26T00:00:00Z',
                '2026-06-26T00:00:00Z'
            );

            INSERT INTO jobs VALUES (
                203,
                'companion.chat',
                'Already attempted',
                'qwen2.5:0.5b',
                'queued',
                1,
                '2026-06-26T00:00:00Z',
                '2026-06-26T00:00:00Z'
            );

            INSERT INTO jobs VALUES (
                204,
                'study.flashcards',
                'Wrong type',
                'qwen2.5:0.5b',
                'queued',
                0,
                '2026-06-26T00:00:00Z',
                '2026-06-26T00:00:00Z'
            );

            INSERT INTO jobs VALUES (
                205,
                'companion.chat',
                'Has result',
                'qwen2.5:0.5b',
                'queued',
                0,
                '2026-06-26T00:00:00Z',
                '2026-06-26T00:00:00Z'
            );

            INSERT INTO job_results VALUES (
                205,
                'backend-deterministic/no-model',
                'done'
            );
            """
        )
        conn.commit()
    finally:
        conn.close()

    text_result = subprocess.run(
        [str(reporter), "--db", str(db), "--expected-marker", "FC-O45-E-CK-K-UNIT-A"],
        text=True,
        capture_output=True,
        check=True,
    )
    text_combined = text_result.stdout + text_result.stderr
    assert "eligible_companion_jobs_read_only=yes" in text_combined, text_combined
    assert "eligible_companion_jobs_total=1" in text_combined, text_combined
    assert "eligible_job id=201" in text_combined, text_combined
    assert "eligible_companion_jobs_report_done=yes" in text_combined, text_combined

    json_result = subprocess.run(
        [str(reporter), "--db", str(db), "--json"],
        text=True,
        capture_output=True,
        check=True,
    )
    payload = json.loads(json_result.stdout)
    assert payload["ok"] is True, payload
    assert payload["db_mode"] == "read_only", payload
    assert payload["total_eligible"] == 2, payload
    assert [job["id"] for job in payload["jobs"]] == [201, 202], payload

print("eligible_companion_job_reporter_offline_unit_smoke_ok=yes")
PY

echo "PASS stage-16-fc-o45-e-ck-k read-only eligible Companion job reporter smoke"
