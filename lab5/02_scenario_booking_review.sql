BEGIN;

INSERT INTO bookings (
    guest_id,
    property_id,
    check_in_date,
    check_out_date,
    total_price,
    status
) VALUES (
    3,
    1,
    DATE '2027-04-01',
    DATE '2027-04-05',
    480.00,
    'completed'
) RETURNING booking_id;

INSERT INTO reviews (booking_id, rating, comment)
SELECT booking_id, 5, 'Transaction committed successfully'
FROM bookings
WHERE guest_id = 3
  AND property_id = 1
  AND check_in_date = DATE '2027-04-01';

COMMIT;

SELECT booking_id, guest_id, property_id, status
FROM bookings
WHERE check_in_date = DATE '2027-04-01';

SELECT r.review_id, r.booking_id, r.rating, r.comment
FROM reviews r
JOIN bookings b ON b.booking_id = r.booking_id
WHERE b.check_in_date = DATE '2027-04-01';

BEGIN;

INSERT INTO bookings (
    guest_id,
    property_id,
    check_in_date,
    check_out_date,
    total_price,
    status
) VALUES (
    4,
    1,
    DATE '2027-05-01',
    DATE '2027-05-05',
    480.00,
    'completed'
);

DO $$
BEGIN
    INSERT INTO reviews (booking_id, rating, comment)
    SELECT booking_id, 9, 'Invalid review'
    FROM bookings
    WHERE guest_id = 4
      AND property_id = 1
      AND check_in_date = DATE '2027-05-01';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Transaction error: %', SQLERRM;
END $$;

ROLLBACK;

SELECT COUNT(*) AS rows_after_full_rollback
FROM bookings
WHERE guest_id = 4
  AND property_id = 1
  AND check_in_date = DATE '2027-05-01';

BEGIN;

INSERT INTO bookings (
    guest_id,
    property_id,
    check_in_date,
    check_out_date,
    total_price,
    status
) VALUES (
    5,
    1,
    DATE '2027-06-01',
    DATE '2027-06-05',
    480.00,
    'completed'
);

SAVEPOINT before_optional_review;

INSERT INTO reviews (booking_id, rating, comment)
SELECT booking_id, 2, 'Draft review with wrong text'
FROM bookings
WHERE guest_id = 5
  AND property_id = 1
  AND check_in_date = DATE '2027-06-01';

ROLLBACK TO SAVEPOINT before_optional_review;

INSERT INTO reviews (booking_id, rating, comment)
SELECT booking_id, 4, 'Corrected review after savepoint rollback'
FROM bookings
WHERE guest_id = 5
  AND property_id = 1
  AND check_in_date = DATE '2027-06-01';

COMMIT;

SELECT b.booking_id, b.status, r.rating, r.comment
FROM bookings b
LEFT JOIN reviews r ON r.booking_id = b.booking_id
WHERE b.guest_id = 5
  AND b.property_id = 1
  AND b.check_in_date = DATE '2027-06-01';
