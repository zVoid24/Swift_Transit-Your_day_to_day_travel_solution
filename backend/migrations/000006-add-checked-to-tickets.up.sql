
-- +migrate Up
ALTER TABLE tickets ADD COLUMN checked BOOLEAN DEFAULT FALSE;
