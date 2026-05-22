BEGIN ISOLATION LEVEL SERIALIZABLE;

SELECT COUNT(*) AS existing_bookings
FROM bookings
WHERE property_id = 3
  AND status = 'confirmed'
  AND check_in_date = DATE '2028-02-01';

SELECT pg_sleep(30);

INSERT INTO bookings (
    guest_id,
    property_id,
    check_in_date,
    check_out_date,
    total_price,
    status
) VALUES (
    3,
    3,
    DATE '2028-02-01',
    DATE '2028-02-05',
    1200.00,
    'confirmed'
);

COMMIT;
