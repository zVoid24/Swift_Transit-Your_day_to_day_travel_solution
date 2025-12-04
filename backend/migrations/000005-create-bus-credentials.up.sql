CREATE TABLE IF NOT EXISTS bus_credentials (
    id SERIAL PRIMARY KEY,
    registration_number VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    route_id INTEGER REFERENCES routes(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
