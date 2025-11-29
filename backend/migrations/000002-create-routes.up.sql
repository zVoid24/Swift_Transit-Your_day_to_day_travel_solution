-- +migrate Up
CREATE TABLE IF NOT EXISTS routes (
    id          SERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    geom        geometry(LineString, 4326)
);