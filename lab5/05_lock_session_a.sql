BEGIN;

UPDATE properties
SET price_per_night = price_per_night + 10
WHERE property_id = 1;

SELECT pg_sleep(30);

COMMIT;

SELECT property_id, price_per_night
FROM properties
WHERE property_id = 1;
