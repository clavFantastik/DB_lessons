BEGIN ISOLATION LEVEL READ COMMITTED;

SELECT price_per_night AS first_read
FROM properties
WHERE property_id = 2;

SELECT pg_sleep(30);

SELECT price_per_night AS second_read
FROM properties
WHERE property_id = 2;

COMMIT;
