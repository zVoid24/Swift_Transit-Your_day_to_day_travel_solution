CREATE TABLE routes (
    id          SERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    geom        geometry(LineString, 4326)
);