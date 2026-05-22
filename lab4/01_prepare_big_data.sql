TRUNCATE reviews, bookings, properties, users, property_types RESTART IDENTITY CASCADE;

SELECT setseed(0.42);

INSERT INTO property_types (name, description) VALUES
    ('Apartment', 'Entire apartment'),
    ('House', 'Entire private house'),
    ('Room', 'Private room in host home'),
    ('Villa', 'Luxury countryside house'),
    ('Studio', 'Studio apartment');

INSERT INTO users (email, password_hash, first_name, last_name, phone, role, created_at, is_verified)
SELECT
    'user' || g || '@example.com',
    md5(g::text),
    'FirstName' || g,
    'LastName' || g,
    '+100000' || lpad(g::text, 8, '0'),
    CASE
        WHEN g % 10 IN (0, 1, 2) THEN 'host'::user_role
        WHEN g % 10 IN (3, 4) THEN 'both'::user_role
        ELSE 'guest'::user_role
    END,
    TIMESTAMP '2023-01-01' + (g % 900) * INTERVAL '1 day',
    g % 7 <> 0
FROM generate_series(1, 50000) AS g;

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
)
SELECT
    ((g * 19) % 50000) + 1,
    ((g - 1) % 5) + 1,
    CASE
        WHEN g % 10 = 0 THEN 'Sea View Villa ' || g
        WHEN g % 10 = 1 THEN 'Central Apartment ' || g
        WHEN g % 10 = 2 THEN 'Budget Studio ' || g
        WHEN g % 10 = 3 THEN 'Family House ' || g
        WHEN g % 10 = 4 THEN 'Quiet Private Room ' || g
        ELSE 'City Stay ' || g
    END,
    CASE
        WHEN g % 8 = 0 THEN 'Spacious apartment with sea view, balcony and fast wifi'
        WHEN g % 8 = 1 THEN 'Central location near metro, museums and restaurants'
        WHEN g % 8 = 2 THEN 'Budget friendly studio for short business trips'
        WHEN g % 8 = 3 THEN 'Family house with kitchen, parking and garden'
        ELSE 'Comfortable place for guests with flexible check in'
    END,
    'Street ' || g,
    (ARRAY['Berlin', 'Paris', 'Rome', 'Madrid', 'Lisbon', 'Prague', 'Amsterdam', 'Barcelona', 'Vienna', 'Warsaw'])[(g % 10) + 1],
    (ARRAY['Germany', 'France', 'Italy', 'Spain', 'Portugal', 'Czech Republic', 'Netherlands', 'Spain', 'Austria', 'Poland'])[(g % 10) + 1],
    (35 + (g % 420) + ((g % 100) / 100.0))::DECIMAL(10, 2),
    (1 + (g % 8)),
    (g % 5),
    (1 + (g % 3)),
    g % 20 <> 0
FROM generate_series(1, 80000) AS g;

INSERT INTO bookings (
    guest_id,
    property_id,
    check_in_date,
    check_out_date,
    total_price,
    status,
    created_at
)
SELECT
    ((g * 17) % 50000) + 1,
    ((g * 13) % 80000) + 1,
    DATE '2024-01-01' + (g % 1095),
    DATE '2024-01-01' + (g % 1095) + (1 + (g % 14)),
    ((45 + (g % 460)) * (1 + (g % 14)))::DECIMAL(10, 2),
    CASE
        WHEN g % 100 < 60 THEN 'completed'::booking_status
        WHEN g % 100 < 80 THEN 'confirmed'::booking_status
        WHEN g % 100 < 95 THEN 'pending'::booking_status
        ELSE 'cancelled'::booking_status
    END,
    TIMESTAMP '2023-01-01' + (g % 1200) * INTERVAL '1 day' + (g % 86400) * INTERVAL '1 second'
FROM generate_series(1, 1000000) AS g;

INSERT INTO reviews (booking_id, rating, comment, created_at)
SELECT
    g,
    (1 + (g % 5))::SMALLINT,
    CASE
        WHEN g % 5 = 0 THEN 'Excellent apartment in central location'
        WHEN g % 5 = 1 THEN 'Good stay and friendly host'
        WHEN g % 5 = 2 THEN 'Average experience for the price'
        WHEN g % 5 = 3 THEN 'Clean room but noisy street'
        ELSE 'Sea view was better than expected'
    END,
    TIMESTAMP '2024-01-01' + (g % 800) * INTERVAL '1 day'
FROM generate_series(1, 1000000, 10) AS g;

ANALYZE users;
ANALYZE property_types;
ANALYZE properties;
ANALYZE bookings;
ANALYZE reviews;
