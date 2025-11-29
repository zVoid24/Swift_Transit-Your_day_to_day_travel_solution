-- +migrate Up
CREATE TABLE tickets (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    route_id INT NOT NULL,
    bus_name VARCHAR(255) NOT NULL,
    start_destination VARCHAR(255) NOT NULL,
    end_destination VARCHAR(255) NOT NULL,
    fare FLOAT NOT NULL,
    paid_status BOOLEAN DEFAULT FALSE,
    qr_code TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
