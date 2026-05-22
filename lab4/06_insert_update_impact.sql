DROP INDEX IF EXISTS idx_lab4_bookings_complex_filter;
DROP INDEX IF EXISTS idx_lab4_bookings_created_at_desc;
DROP INDEX IF EXISTS idx_lab4_bookings_property_status_date;
DROP INDEX IF EXISTS idx_lab4_bookings_status_property_date;
DROP INDEX IF EXISTS idx_lab4_bookings_join_status_property;
DROP INDEX IF EXISTS idx_lab4_bookings_total_price;

ANALYZE bookings;

EXPLAIN (ANALYZE, BUFFERS)
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
    DATE '2027-01-01' + (g % 180),
    DATE '2027-01-01' + (g % 180) + (1 + (g % 10)),
    ((60 + (g % 300)) * (1 + (g % 10)))::DECIMAL(10, 2),
    'pending'::booking_status,
    TIMESTAMP '2026-01-01' + (g % 180) * INTERVAL '1 day'
FROM generate_series(1, 20000) AS g;

DELETE FROM bookings
WHERE created_at >= TIMESTAMP '2026-01-01'
  AND check_in_date >= DATE '2027-01-01';

EXPLAIN (ANALYZE, BUFFERS)
UPDATE bookings
SET total_price = total_price + 1
WHERE booking_id IN (
    SELECT booking_id
    FROM bookings
    WHERE status = 'pending'
    LIMIT 20000
);

UPDATE bookings
SET total_price = total_price - 1
WHERE booking_id IN (
    SELECT booking_id
    FROM bookings
    WHERE status = 'pending'
    LIMIT 20000
);

CREATE INDEX IF NOT EXISTS idx_lab4_bookings_complex_filter
ON bookings (status, check_in_date, total_price);

CREATE INDEX IF NOT EXISTS idx_lab4_bookings_created_at_desc
ON bookings (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_lab4_bookings_property_status_date
ON bookings (property_id, status, check_in_date);

CREATE INDEX IF NOT EXISTS idx_lab4_bookings_status_property_date
ON bookings (status, property_id, check_in_date);

CREATE INDEX IF NOT EXISTS idx_lab4_bookings_join_status_property
ON bookings (status, check_in_date, property_id);

CREATE INDEX IF NOT EXISTS idx_lab4_bookings_total_price
ON bookings (total_price);

ANALYZE bookings;

EXPLAIN (ANALYZE, BUFFERS)
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
    DATE '2027-01-01' + (g % 180),
    DATE '2027-01-01' + (g % 180) + (1 + (g % 10)),
    ((60 + (g % 300)) * (1 + (g % 10)))::DECIMAL(10, 2),
    'pending'::booking_status,
    TIMESTAMP '2026-01-01' + (g % 180) * INTERVAL '1 day'
FROM generate_series(1, 20000) AS g;

DELETE FROM bookings
WHERE created_at >= TIMESTAMP '2026-01-01'
  AND check_in_date >= DATE '2027-01-01';

EXPLAIN (ANALYZE, BUFFERS)
UPDATE bookings
SET total_price = total_price + 1
WHERE booking_id IN (
    SELECT booking_id
    FROM bookings
    WHERE status = 'pending'
    LIMIT 20000
);

UPDATE bookings
SET total_price = total_price - 1
WHERE booking_id IN (
    SELECT booking_id
    FROM bookings
    WHERE status = 'pending'
    LIMIT 20000
);
