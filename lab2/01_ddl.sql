DROP VIEW IF EXISTS v_active_bookings;
DROP VIEW IF EXISTS v_host_revenue;
DROP VIEW IF EXISTS v_property_summary;

DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS properties;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS property_types;

DROP TYPE IF EXISTS booking_status;
DROP TYPE IF EXISTS user_role;

CREATE TYPE user_role      AS ENUM ('host', 'guest', 'both');
CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'cancelled', 'completed');

CREATE TABLE property_types (
    type_id     SERIAL      PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE users (
    user_id       SERIAL       PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name    VARCHAR(100) NOT NULL,
    last_name     VARCHAR(100) NOT NULL,
    phone         VARCHAR(20),
    role          user_role    NOT NULL,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_verified   BOOLEAN      NOT NULL DEFAULT FALSE
);

CREATE TABLE properties (
    property_id     SERIAL         PRIMARY KEY,
    host_id         INTEGER        NOT NULL REFERENCES users(user_id)          ON DELETE RESTRICT,
    type_id         INTEGER        NOT NULL REFERENCES property_types(type_id) ON DELETE RESTRICT,
    title           VARCHAR(255)   NOT NULL,
    description     TEXT,
    address         VARCHAR(255)   NOT NULL,
    city            VARCHAR(100)   NOT NULL,
    country         VARCHAR(100)   NOT NULL,
    price_per_night DECIMAL(10, 2) NOT NULL CHECK (price_per_night > 0),
    max_guests      INTEGER        NOT NULL CHECK (max_guests > 0),
    bedrooms        INTEGER                 CHECK (bedrooms >= 0),
    bathrooms       INTEGER                 CHECK (bathrooms >= 0),
    is_active       BOOLEAN        NOT NULL DEFAULT TRUE
);

CREATE TABLE bookings (
    booking_id     SERIAL         PRIMARY KEY,
    guest_id       INTEGER        NOT NULL REFERENCES users(user_id)          ON DELETE RESTRICT,
    property_id    INTEGER        NOT NULL REFERENCES properties(property_id) ON DELETE RESTRICT,
    check_in_date  DATE           NOT NULL,
    check_out_date DATE           NOT NULL,
    total_price    DECIMAL(10, 2) NOT NULL CHECK (total_price > 0),
    status         booking_status NOT NULL DEFAULT 'pending',
    created_at     TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_dates CHECK (check_out_date > check_in_date)
);

CREATE TABLE reviews (
    review_id  SERIAL    PRIMARY KEY,
    booking_id INTEGER   NOT NULL UNIQUE REFERENCES bookings(booking_id) ON DELETE CASCADE,
    rating     SMALLINT  NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment    TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_properties_host    ON properties(host_id);
CREATE INDEX idx_properties_city    ON properties(city, country);
CREATE INDEX idx_bookings_guest     ON bookings(guest_id);
CREATE INDEX idx_bookings_property  ON bookings(property_id, check_in_date, check_out_date);
