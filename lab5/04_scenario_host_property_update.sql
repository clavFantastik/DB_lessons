BEGIN;

UPDATE users
SET is_verified = FALSE
WHERE user_id = 1;

UPDATE properties
SET is_active = FALSE
WHERE host_id = 1;

COMMIT;

SELECT u.user_id, u.is_verified, COUNT(p.property_id) FILTER (WHERE p.is_active = FALSE) AS inactive_properties
FROM users u
LEFT JOIN properties p ON p.host_id = u.user_id
WHERE u.user_id = 1
GROUP BY u.user_id, u.is_verified;

BEGIN;

UPDATE users
SET phone = '+19999999999'
WHERE user_id = 2;

DO $$
BEGIN
    UPDATE properties
    SET max_guests = 0
    WHERE host_id = 2;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Transaction error: %', SQLERRM;
END $$;

ROLLBACK;

SELECT u.user_id, u.phone, p.property_id, p.max_guests
FROM users u
JOIN properties p ON p.host_id = u.user_id
WHERE u.user_id = 2;

BEGIN;

UPDATE users
SET phone = '+18888888888'
WHERE user_id = 2;

SAVEPOINT before_price_discount;

UPDATE properties
SET price_per_night = price_per_night * 0.50
WHERE host_id = 2;

ROLLBACK TO SAVEPOINT before_price_discount;

UPDATE properties
SET description = description || ' Updated by transaction'
WHERE host_id = 2;

COMMIT;

SELECT u.user_id, u.phone, p.property_id, p.price_per_night, p.description
FROM users u
JOIN properties p ON p.host_id = u.user_id
WHERE u.user_id = 2;
