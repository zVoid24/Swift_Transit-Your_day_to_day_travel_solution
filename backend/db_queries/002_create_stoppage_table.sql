CREATE TABLE stops (
    id         SERIAL PRIMARY KEY,
    route_id   INT REFERENCES routes(id) ON DELETE CASCADE,
    name       TEXT NOT NULL,
    stop_order INT NOT NULL,
    geom       geometry(Point, 4326)
);