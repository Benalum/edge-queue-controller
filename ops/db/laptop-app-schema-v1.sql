-- AI Platform Controller Laptop App Schema v1
--
-- Purpose:
--   Empty foundation schema for the future laptop-owned source-of-truth database.
--
-- Important:
--   This schema does not migrate CT101 data.
--   The controller runtime still uses edge_queue.sqlite3 until a later stage.

BEGIN;

CREATE TABLE IF NOT EXISTS app_schema_migrations (
    version TEXT PRIMARY KEY,
    description TEXT NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS app_users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    display_name TEXT,
    password_hash TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_admin BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_login_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS app_sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    token_hash TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS app_chats (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    mode TEXT NOT NULL DEFAULT 'chat',
    title TEXT,
    model TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT app_chats_mode_check CHECK (mode IN ('chat', 'companion'))
);

CREATE TABLE IF NOT EXISTS app_messages (
    id TEXT PRIMARY KEY,
    chat_id TEXT NOT NULL REFERENCES app_chats(id) ON DELETE CASCADE,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    risk_level INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT app_messages_role_check CHECK (role IN ('system', 'user', 'assistant', 'tool'))
);

CREATE TABLE IF NOT EXISTS app_jobs (
    id TEXT PRIMARY KEY,
    user_id TEXT REFERENCES app_users(id) ON DELETE SET NULL,
    job_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'queued',
    requested_model TEXT,
    assigned_worker_id TEXT,
    payload_json JSONB,
    result_json JSONB,
    error_text TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    CONSTRAINT app_jobs_status_check CHECK (status IN ('queued', 'running', 'complete', 'failed', 'cancelled'))
);

CREATE TABLE IF NOT EXISTS app_worker_nodes (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    node_type TEXT,
    host_machine TEXT,
    tailscale_ip TEXT,
    lan_ip TEXT,
    compose_path TEXT,
    start_command TEXT,
    stop_command TEXT,
    wake_method TEXT,
    wake_target TEXT,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    status TEXT NOT NULL DEFAULT 'unknown',
    capabilities JSONB,
    notes TEXT,
    last_seen_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS app_workers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'unknown',
    capabilities_json JSONB,
    current_job_id TEXT,
    worker_node_id TEXT REFERENCES app_worker_nodes(id) ON DELETE SET NULL,
    last_heartbeat_at TIMESTAMPTZ,
    idle_shutdown_seconds INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_app_sessions_user_id ON app_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_app_sessions_token_hash ON app_sessions(token_hash);
CREATE INDEX IF NOT EXISTS idx_app_chats_user_id ON app_chats(user_id);
CREATE INDEX IF NOT EXISTS idx_app_chats_mode ON app_chats(mode);
CREATE INDEX IF NOT EXISTS idx_app_messages_chat_id_created_at ON app_messages(chat_id, created_at);
CREATE INDEX IF NOT EXISTS idx_app_jobs_status_created_at ON app_jobs(status, created_at);
CREATE INDEX IF NOT EXISTS idx_app_jobs_type_status ON app_jobs(job_type, status);
CREATE INDEX IF NOT EXISTS idx_app_jobs_assigned_worker_id ON app_jobs(assigned_worker_id);
CREATE INDEX IF NOT EXISTS idx_app_workers_status ON app_workers(status);
CREATE INDEX IF NOT EXISTS idx_app_workers_worker_node_id ON app_workers(worker_node_id);
CREATE INDEX IF NOT EXISTS idx_app_worker_nodes_status ON app_worker_nodes(status);

INSERT INTO app_schema_migrations (version, description)
VALUES ('2026-06-07-stage-5d4-app-foundation-v1', 'Initial laptop app foundation schema')
ON CONFLICT (version) DO NOTHING;

COMMIT;
