-- +migrate Up
ALTER TABLE bus_credentials
ADD COLUMN IF NOT EXISTS route_id_up INTEGER REFERENCES routes(id),
ADD COLUMN IF NOT EXISTS route_id_down INTEGER REFERENCES routes(id);

UPDATE bus_credentials
SET route_id_up = COALESCE(route_id_up, route_id);

ALTER TABLE bus_credentials
DROP COLUMN IF EXISTS route_id;
