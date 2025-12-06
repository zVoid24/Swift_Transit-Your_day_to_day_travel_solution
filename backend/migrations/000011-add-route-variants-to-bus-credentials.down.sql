-- +migrate Down
ALTER TABLE bus_credentials
ADD COLUMN IF NOT EXISTS route_id INTEGER REFERENCES routes(id);

UPDATE bus_credentials
SET route_id = COALESCE(route_id_up, route_id_down, route_id);

ALTER TABLE bus_credentials
DROP COLUMN IF EXISTS route_id_up,
DROP COLUMN IF EXISTS route_id_down;
