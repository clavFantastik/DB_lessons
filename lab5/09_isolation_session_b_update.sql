BEGIN;

UPDATE properties
SET price_per_night = price_per_night + 50
WHERE property_id = 2;

COMMIT;

SELECT price_per_night
FROM properties
WHERE property_id = 2;
