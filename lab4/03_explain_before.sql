EXPLAIN (ANALYZE, BUFFERS)
SELECT
    COUNT(*) AS booking_count,
    SUM(total_price) AS total_amount
FROM bookings
WHERE status = 'confirmed'
  AND check_in_date BETWEEN DATE '2025-06-01' AND DATE '2025-12-31'
  AND total_price BETWEEN 500 AND 2000;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    booking_id,
    guest_id,
    property_id,
    status,
    created_at,
    total_price
FROM bookings
WHERE status IN ('confirmed', 'pending')
ORDER BY created_at DESC
LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    COUNT(*) AS booking_count,
    SUM(total_price) AS total_amount
FROM bookings
WHERE property_id = 2494
  AND status = 'confirmed'
  AND check_in_date >= DATE '2025-01-01';

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    property_id,
    title,
    city,
    price_per_night
FROM properties
WHERE title ILIKE '%Villa%'
   OR description ILIKE '%sea view%'
   OR title ILIKE 'Central%'
   OR title ILIKE '%777';

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    p.property_id,
    p.title,
    h.email AS host_email,
    COUNT(b.booking_id) AS confirmed_bookings,
    SUM(b.total_price) AS confirmed_revenue
FROM properties p
JOIN users h ON h.user_id = p.host_id
JOIN bookings b ON b.property_id = p.property_id
WHERE p.city = 'Paris'
  AND b.status = 'confirmed'
  AND b.check_in_date >= DATE '2025-01-01'
GROUP BY p.property_id, p.title, h.email
ORDER BY confirmed_revenue DESC
LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    COUNT(*) AS almost_all_bookings
FROM bookings
WHERE total_price > 0;
