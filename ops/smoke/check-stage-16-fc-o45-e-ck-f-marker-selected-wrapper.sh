#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

SELECTOR="ops/workers/run-next-deterministic-companion-systemd-once.sh"
DOC="docs/stage-16-fc-o45-e-ck-f-marker-selected-manual-companion-wrapper.md"

test -f "$SELECTOR"
test -x "$SELECTOR"
test -f "$DOC"

grep -Fq "Usage:" "$SELECTOR"
grep -Fq -- "--expected-marker" "$SELECTOR"
grep -Fq "run-deterministic-companion-systemd-once.sh" "$SELECTOR"
grep -Fq "candidate_count" "$SELECTOR"
grep -Fq "REFUSE_NO_ELIGIBLE_QUEUED_COMPANION_JOB_FOR_MARKER" "$SELECTOR"
grep -Fq "REFUSE_MULTIPLE_ELIGIBLE_JOBS_FOR_MARKER" "$SELECTOR"
grep -Fq "job_type = 'companion.chat'" "$SELECTOR"
grep -Fq "j.status = 'queued'" "$SELECTOR"
grep -Fq "COALESCE(j.attempts, 0) = 0" "$SELECTOR"
grep -Fq "COALESCE(r.result_rows, 0) = 0" "$SELECTOR"
grep -Fq 'exec "$WRAPPER" --job-id "$JOB_ID" --expected-marker "$EXPECTED_MARKER"' "$SELECTOR"

grep -Fq "Marker-Selected Manual Companion Wrapper" "$DOC"
grep -Fq "ops/workers/run-next-deterministic-companion-systemd-once.sh" "$DOC"
grep -Fq "exactly one queued" "$DOC"
grep -Fq "attempts=0" "$DOC"
grep -Fq "result_rows=0" "$DOC"
grep -Fq "does not insert jobs" "$DOC"
grep -Fq "does not poll the queue" "$DOC"
grep -Fq "does not enable a service" "$DOC"
grep -Fq "does not install or enable a timer" "$DOC"
grep -Fq "does not activate a persistent worker" "$DOC"
grep -Fq "does not call PVESO, Ollama, or any model endpoint" "$DOC"

bash -n "$SELECTOR"

python3 - <<'PY'
import sqlite3
import subprocess
import tempfile
from pathlib import Path

selector = Path("ops/workers/run-next-deterministic-companion-systemd-once.sh").resolve()

with tempfile.TemporaryDirectory() as td:
    db = Path(td) / "queue.sqlite3"
    wrapper = Path(td) / "delegate.sh"
    wrapper.write_text("#!/usr/bin/env bash\necho delegated_job_id=$2 marker=$4\n")
    wrapper.chmod(0o755)

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
                attempts INTEGER
            );
            CREATE TABLE job_results (
                job_id INTEGER,
                model TEXT,
                response_text TEXT
            );
            INSERT INTO jobs VALUES (
                123,
                'companion.chat',
                'Please answer exactly: FC-O45-E-CK-F-UNIT-OK',
                'qwen2.5:0.5b',
                'queued',
                0
            );
            """
        )
        conn.commit()
    finally:
        conn.close()

    result = subprocess.run(
        [
            str(selector),
            "--expected-marker",
            "FC-O45-E-CK-F-UNIT-OK",
            "--db",
            str(db),
            "--wrapper",
            str(wrapper),
        ],
        text=True,
        capture_output=True,
        check=True,
    )

    combined = result.stdout + result.stderr
    assert "marker_selected_wrapper_job_id=123" in combined, combined
    assert "delegated_job_id=123 marker=FC-O45-E-CK-F-UNIT-OK" in combined, combined

print("marker_selected_wrapper_offline_unit_smoke_ok=yes")
PY

echo "PASS stage-16-fc-o45-e-ck-f-r2 marker-selected manual wrapper smoke"
