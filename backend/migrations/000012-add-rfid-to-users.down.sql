-- +migrate Down
ALTER TABLE users DROP COLUMN rfid;
