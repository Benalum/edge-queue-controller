-- Phase 14J-AA default-off worker registry lane metadata schema artifact.
--
-- IMPORTANT:
-- This file is an artifact only in Phase 14J-AA.
-- Do not apply this file directly in Phase 14J-AA.
-- A future apply wrapper must inspect existing columns first and only run
-- missing-column ALTER statements.
--
-- Target:
--   SQLite DB: edge_queue.sqlite3
--   Table: workers
--
-- Default-off policy:
--   Existing workers default to primary/non-lane behavior.
--   Existing workers do not accept lane jobs by default.
--   This schema support alone must not enable persistent lane filtering.
--   EDGE_PERSISTENT_LANE_WORKERS_ENABLED must remain absent or disabled.

ALTER TABLE workers ADD COLUMN worker_role TEXT DEFAULT 'primary';
ALTER TABLE workers ADD COLUMN worker_lane TEXT DEFAULT '';
ALTER TABLE workers ADD COLUMN accepts_lane_jobs INTEGER DEFAULT 0;
ALTER TABLE workers ADD COLUMN capabilities TEXT DEFAULT '[]';
ALTER TABLE workers ADD COLUMN disabled INTEGER DEFAULT 0;
ALTER TABLE workers ADD COLUMN current_running_jobs INTEGER DEFAULT 0;
ALTER TABLE workers ADD COLUMN state TEXT DEFAULT 'available';
ALTER TABLE workers ADD COLUMN computed_health TEXT DEFAULT '';
