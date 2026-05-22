BEGIN;

UPDATE bookings
SET status = 'cancelled'
WHERE booking_id = 1;

UPDATE properties
SET is_active = FALSE
WHERE property_id = 1;

COMMIT;

SELECT b.booking_id, b.status, p.property_id, p.is_active
FROM bookings b
JOIN properties p ON p.property_id = b.property_id
WHERE b.booking_id = 1;

BEGIN;

UPDATE bookings
SET status = 'cancelled'
WHERE booking_id = 2;

DO $$
BEGIN
    UPDATE properties
    SET price_per_night = -100
    WHERE property_id = 2;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Transaction error: %', SQLERRM;
END $$;

ROLLBACK;

SELECT b.booking_id, b.status, p.property_id, p.price_per_night
FROM bookings b
JOIN properties p ON p.property_id = b.property_id
WHERE b.booking_id = 2;

BEGIN;

UPDATE bookings
SET status = 'cancelled'
WHERE booking_id = 2;

SAVEPOINT before_property_deactivation;

UPDATE properties
SET is_active = FALSE
WHERE property_id = 2;

ROLLBACK TO SAVEPOINT before_property_deactivation;

UPDATE properties
SET price_per_night = price_per_night + 20
WHERE property_id = 2;

COMMIT;

SELECT b.booking_id, b.status, p.property_id, p.is_active, p.price_per_night
FROM bookings b
JOIN properties p ON p.property_id = b.property_id
WHERE b.booking_id = 2;
