-- Laptop app schema v2 — Stage 5F-4
-- Adds queued-chat assistant message idempotency support.
--
-- Safe/idempotent:
-- - adds app_messages.source_job_id if missing
-- - adds unique partial index for non-null source_job_id
-- - records migration marker
--
-- This does not change production chat behavior.

BEGIN;

ALTER TABLE app_messages
ADD COLUMN IF NOT EXISTS source_job_id TEXT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_app_messages_source_job_id_unique
ON app_messages(source_job_id)
WHERE source_job_id IS NOT NULL;

INSERT INTO app_schema_migrations (version, description)
VALUES (
  'stage-5f4-chat-source-job-id',
  'Add app_messages.source_job_id and unique partial index for queued chat idempotency'
)
ON CONFLICT (version) DO NOTHING;

COMMIT;
