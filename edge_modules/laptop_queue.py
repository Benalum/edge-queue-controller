"""
Laptop-owned Postgres queue helper.

Stage 5E-3 helper module.

This module is intentionally not wired into the live controller routes yet.
It is used by synthetic smoke tests to prove laptop-owned queue behavior
before CT101 workers are connected to laptop Postgres.

No production data migration happens here.
"""

from __future__ import annotations

import json
import os
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Any


DEFAULT_ENV_FILE = Path.home() / ".config" / "ai-platform-controller" / "postgres.env"


class LaptopQueueError(RuntimeError):
    pass


def _load_env_file(env_file: str | os.PathLike[str] | None = None) -> dict[str, str]:
    path = Path(env_file or os.environ.get("AI_PLATFORM_CONTROLLER_DB_ENV", DEFAULT_ENV_FILE))

    if not path.exists():
        raise LaptopQueueError(f"Missing laptop Postgres env file: {path}")

    values: dict[str, str] = {}

    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()

        if not line or line.startswith("#"):
            continue

        if "=" not in line:
            continue

        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")

    return values


def _sql_literal(value: Any) -> str:
    if value is None:
        return "NULL"

    text = str(value)
    return "'" + text.replace("'", "''") + "'"


def _jsonb_literal(value: Any) -> str:
    return _sql_literal(json.dumps(value, separators=(",", ":"), sort_keys=True)) + "::jsonb"


@dataclass
class LaptopQueueClient:
    database_url: str | None = None
    env_file: str | os.PathLike[str] | None = None

    def __post_init__(self) -> None:
        if not self.database_url:
            env_values = _load_env_file(self.env_file)
            self.database_url = env_values.get("DATABASE_URL")

        if not self.database_url:
            raise LaptopQueueError("DATABASE_URL is not configured")

    def psql_at(self, sql: str) -> str:
        result = subprocess.run(
            [
                "psql",
                self.database_url,
                "-P",
                "pager=off",
                "-q",
                "-v",
                "ON_ERROR_STOP=1",
                "-Atc",
                sql,
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        return result.stdout.strip()

    def psql_run(self, sql: str) -> None:
        subprocess.run(
            [
                "psql",
                self.database_url,
                "-P",
                "pager=off",
                "-q",
                "-v",
                "ON_ERROR_STOP=1",
            ],
            input=sql,
            check=True,
            capture_output=True,
            text=True,
        )

    def table_exists(self, table_name: str) -> bool:
        value = self.psql_at(f"SELECT to_regclass('public.{table_name}') IS NOT NULL;")
        return value == "t"

    def create_synthetic_user(self, *, user_id: str, email: str, display_name: str) -> None:
        self.psql_run(
            f"""
            INSERT INTO app_users (
                id,
                email,
                display_name,
                password_hash,
                is_active,
                is_admin
            )
            VALUES (
                {_sql_literal(user_id)},
                {_sql_literal(email)},
                {_sql_literal(display_name)},
                'stage-5e3-not-a-real-password',
                TRUE,
                FALSE
            );
            """
        )

    def create_synthetic_worker_node(
        self,
        *,
        node_id: str,
        name: str,
        capabilities: dict[str, Any] | None = None,
    ) -> None:
        self.psql_run(
            f"""
            INSERT INTO app_worker_nodes (
                id,
                name,
                node_type,
                host_machine,
                tailscale_ip,
                enabled,
                status,
                capabilities,
                notes
            )
            VALUES (
                {_sql_literal(node_id)},
                {_sql_literal(name)},
                'synthetic',
                'laptop-controller',
                '127.0.0.1',
                TRUE,
                'online',
                {_jsonb_literal(capabilities or {"job_types": ["ollama_chat"]})},
                'Synthetic smoke row; safe to delete.'
            );
            """
        )

    def create_synthetic_worker(
        self,
        *,
        worker_id: str,
        node_id: str,
        name: str,
        capabilities: dict[str, Any] | None = None,
    ) -> None:
        self.psql_run(
            f"""
            INSERT INTO app_workers (
                id,
                name,
                status,
                capabilities_json,
                current_job_id,
                worker_node_id,
                last_heartbeat_at,
                idle_shutdown_seconds
            )
            VALUES (
                {_sql_literal(worker_id)},
                {_sql_literal(name)},
                'idle',
                {_jsonb_literal(capabilities or {"job_types": ["ollama_chat"]})},
                NULL,
                {_sql_literal(node_id)},
                now(),
                300
            );
            """
        )

    def create_job(
        self,
        *,
        job_id: str,
        user_id: str | None,
        job_type: str,
        payload: dict[str, Any] | None = None,
        requested_model: str | None = None,
    ) -> None:
        self.psql_run(
            f"""
            INSERT INTO app_jobs (
                id,
                user_id,
                job_type,
                status,
                requested_model,
                assigned_worker_id,
                payload_json
            )
            VALUES (
                {_sql_literal(job_id)},
                {_sql_literal(user_id)},
                {_sql_literal(job_type)},
                'queued',
                {_sql_literal(requested_model)},
                NULL,
                {_jsonb_literal(payload or {})}
            );
            """
        )

    def claim_next_job(self, *, worker_id: str, job_type: str | None = None) -> dict[str, Any] | None:
        job_type_filter = ""
        if job_type:
            job_type_filter = f"AND job_type = {_sql_literal(job_type)}"

        raw = self.psql_at(
            f"""
            WITH next_job AS (
                SELECT id
                FROM app_jobs
                WHERE status = 'queued'
                  {job_type_filter}
                ORDER BY created_at, id
                LIMIT 1
                FOR UPDATE SKIP LOCKED
            ),
            updated_job AS (
                UPDATE app_jobs j
                SET status = 'running',
                    assigned_worker_id = {_sql_literal(worker_id)},
                    started_at = COALESCE(started_at, now()),
                    updated_at = now()
                FROM next_job
                WHERE j.id = next_job.id
                RETURNING
                    j.id,
                    j.user_id,
                    j.job_type,
                    j.status,
                    j.requested_model,
                    j.assigned_worker_id,
                    j.payload_json,
                    j.result_json,
                    j.error_text,
                    j.created_at,
                    j.updated_at,
                    j.started_at,
                    j.finished_at
            ),
            updated_worker AS (
                UPDATE app_workers
                SET status = 'busy',
                    current_job_id = (SELECT id FROM updated_job),
                    updated_at = now()
                WHERE id = {_sql_literal(worker_id)}
                  AND EXISTS (SELECT 1 FROM updated_job)
                RETURNING id
            )
            SELECT COALESCE((SELECT row_to_json(u)::text FROM updated_job u), '');
            """
        )

        if not raw:
            return None

        return json.loads(raw)

    def complete_job(
        self,
        *,
        job_id: str,
        worker_id: str,
        ok: bool,
        result: dict[str, Any] | None = None,
        error_text: str | None = None,
    ) -> dict[str, Any]:
        status = "complete" if ok else "failed"
        result_sql = _jsonb_literal(result or {}) if ok else "NULL"
        error_sql = "NULL" if ok else _sql_literal(error_text or "Job failed")

        raw = self.psql_at(
            f"""
            WITH updated_job AS (
                UPDATE app_jobs
                SET status = {_sql_literal(status)},
                    result_json = {result_sql},
                    error_text = {error_sql},
                    finished_at = now(),
                    updated_at = now()
                WHERE id = {_sql_literal(job_id)}
                  AND assigned_worker_id = {_sql_literal(worker_id)}
                  AND status = 'running'
                RETURNING
                    id,
                    user_id,
                    job_type,
                    status,
                    requested_model,
                    assigned_worker_id,
                    payload_json,
                    result_json,
                    error_text,
                    created_at,
                    updated_at,
                    started_at,
                    finished_at
            ),
            updated_worker AS (
                UPDATE app_workers
                SET status = 'idle',
                    current_job_id = NULL,
                    updated_at = now()
                WHERE id = {_sql_literal(worker_id)}
                  AND current_job_id = {_sql_literal(job_id)}
                  AND EXISTS (SELECT 1 FROM updated_job)
                RETURNING id
            )
            SELECT COALESCE((SELECT row_to_json(u)::text FROM updated_job u), '');
            """
        )

        if not raw:
            raise LaptopQueueError(f"Could not complete job {job_id}")

        return json.loads(raw)

    def get_worker_state(self, *, worker_id: str) -> str | None:
        value = self.psql_at(
            f"""
            SELECT status || '|' || COALESCE(current_job_id, '')
            FROM app_workers
            WHERE id = {_sql_literal(worker_id)};
            """
        )
        return value or None

    def get_job_json_field(self, *, job_id: str, field_name: str) -> str | None:
        value = self.psql_at(
            f"""
            SELECT COALESCE(result_json->>{_sql_literal(field_name)}, '')
            FROM app_jobs
            WHERE id = {_sql_literal(job_id)};
            """
        )
        return value or None

    def get_job_error(self, *, job_id: str) -> str | None:
        value = self.psql_at(
            f"""
            SELECT COALESCE(error_text, '')
            FROM app_jobs
            WHERE id = {_sql_literal(job_id)};
            """
        )
        return value or None

    def cleanup_synthetic(
        self,
        *,
        user_id: str,
        node_id: str,
        worker_id: str,
        job_ids: list[str],
    ) -> None:
        job_list = ", ".join(_sql_literal(job_id) for job_id in job_ids) or "NULL"

        self.psql_run(
            f"""
            DELETE FROM app_jobs
            WHERE id IN ({job_list})
               OR user_id = {_sql_literal(user_id)};

            DELETE FROM app_workers
            WHERE id = {_sql_literal(worker_id)};

            DELETE FROM app_worker_nodes
            WHERE id = {_sql_literal(node_id)};

            DELETE FROM app_users
            WHERE id = {_sql_literal(user_id)};
            """
        )

    def synthetic_leftover_count(
        self,
        *,
        user_id: str,
        node_id: str,
        worker_id: str,
        job_ids: list[str],
    ) -> int:
        job_list = ", ".join(_sql_literal(job_id) for job_id in job_ids) or "NULL"

        value = self.psql_at(
            f"""
            SELECT
              (
                SELECT COUNT(*) FROM app_jobs
                WHERE id IN ({job_list})
                   OR user_id = {_sql_literal(user_id)}
              )
              +
              (
                SELECT COUNT(*) FROM app_workers
                WHERE id = {_sql_literal(worker_id)}
              )
              +
              (
                SELECT COUNT(*) FROM app_worker_nodes
                WHERE id = {_sql_literal(node_id)}
              )
              +
              (
                SELECT COUNT(*) FROM app_users
                WHERE id = {_sql_literal(user_id)}
              );
            """
        )

        return int(value or "0")
