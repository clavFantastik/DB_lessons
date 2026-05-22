TRUNCATE reviews, bookings, properties, users, property_types RESTART IDENTITY CASCADE;

INSERT INTO property_types (name, description) VALUES
    ('Apartment', 'Entire apartment'),
    ('House', 'Entire private house'),
    ('Room', 'Private room in host home'),
    ('Villa', 'Luxury countryside house'),
    ('Studio', 'Studio apartment');

INSERT INTO users (email, password_hash, first_name, last_name, phone, role, is_verified) VALUES
    ('host1@example.com', md5('host1'), 'John', 'Host', '+10000000001', 'host', TRUE),
    ('host2@example.com', md5('host2'), 'Emma', 'Host', '+10000000002', 'host', TRUE),
    ('guest1@example.com', md5('guest1'), 'Alice', 'Guest', '+10000000003', 'guest', TRUE),
    ('guest2@example.com', md5('guest2'), 'Bob', 'Guest', '+10000000004', 'guest', TRUE),
    ('guest3@example.com', md5('guest3'), 'Carol', 'Guest', '+10000000005', 'guest', TRUE),
    ('both1@example.com', md5('both1'), 'Daniel', 'Both', '+10000000006', 'both', TRUE);

INSERT INTO properties (
    host_id,
    type_id,
    title,
    description,
    address,
    city,
    country,
    price_per_night,
    max_guests,
    bedrooms,
    bathrooms,
    is_active
) VALUES
    (1, 1, 'Central Apartment for Transactions', 'Apartment for transaction laboratory', 'Main Street 1', 'Berlin', 'Germany', 120.00, 2, 1, 1, TRUE),
    (1, 2, 'Family House for Isolation', 'House for isolation laboratory', 'Main Street 2', 'Paris', 'France', 180.00, 5, 3, 2, TRUE),
    (2, 4, 'Serializable Villa', 'Villa for concurrent booking laboratory', 'Main Street 3', 'Rome', 'Italy', 300.00, 8, 4, 3, TRUE);

INSERT INTO bookings (
    guest_id,
    property_id,
    check_in_date,
    check_out_date,
    total_price,
    status,
    created_at
) VALUES
    (3, 1, DATE '2027-01-10', DATE '2027-01-15', 600.00, 'confirmed', TIMESTAMP '2026-01-01 10:00:00'),
    (4, 2, DATE '2027-02-10', DATE '2027-02-15', 900.00, 'confirmed', TIMESTAMP '2026-01-02 10:00:00'),
    (5, 1, DATE '2027-03-10', DATE '2027-03-15', 600.00, 'completed', TIMESTAMP '2026-01-03 10:00:00');

ANALYZE users;
ANALYZE property_types;
ANALYZE properties;
ANALYZE bookings;
ANALYZE reviews;
