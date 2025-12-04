-- +migrate Down
ALTER TABLE tickets DROP COLUMN checked;
