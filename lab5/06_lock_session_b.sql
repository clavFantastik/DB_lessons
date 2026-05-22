SET lock_timeout = '5s';

BEGIN;

UPDATE properties
SET price_per_night = price_per_night + 20
WHERE property_id = 1;

COMMIT;

RESET lock_timeout;

SELECT property_id, price_per_night
FROM properties
WHERE property_id = 1;
