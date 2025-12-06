-- +migrate Up
ALTER TABLE users ADD COLUMN is_rfid_active BOOLEAN DEFAULT TRUE;
