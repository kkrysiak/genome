-- Revert process.process.created_by_index

BEGIN;

DROP INDEX process.process_process_created_by_idx;

COMMIT;
