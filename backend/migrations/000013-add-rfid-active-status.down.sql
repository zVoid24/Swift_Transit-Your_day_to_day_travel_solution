-- +migrate Down
ALTER TABLE users DROP COLUMN is_rfid_active;
