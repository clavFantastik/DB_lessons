-- (INNER JOIN): все бронирования с именем гостя и названием объекта
SELECT
    b.booking_id,
    g.first_name || ' ' || g.last_name AS guest_name,
    p.title                            AS property_title,
    p.city,
    b.check_in_date,
    b.check_out_date,
    b.total_price,
    b.status
FROM bookings b
INNER JOIN users g      ON g.user_id     = b.guest_id
INNER JOIN properties p ON p.property_id = b.property_id
ORDER BY b.check_in_date;

-- (LEFT JOIN): все объекты с количеством отзывов (включая 0)
SELECT
    p.title,
    p.city,
    pt.name            AS property_type,
    p.price_per_night,
    COUNT(r.review_id) AS review_count
FROM properties p
JOIN property_types pt  ON pt.type_id    = p.type_id
LEFT JOIN bookings b    ON b.property_id = p.property_id
LEFT JOIN reviews r     ON r.booking_id  = b.booking_id
GROUP BY p.property_id, p.title, p.city, pt.name, p.price_per_night
ORDER BY review_count DESC;

-- (многотабличный JOIN): полная цепочка гость -> бронь -> объект -> хост -> отзыв
SELECT
    b.booking_id,
    g.first_name || ' ' || g.last_name AS guest_name,
    g.email                            AS guest_email,
    p.title                            AS property_title,
    p.city,
    h.first_name || ' ' || h.last_name AS host_name,
    b.check_in_date,
    b.check_out_date,
    b.total_price,
    b.status,
    r.rating
FROM bookings b
JOIN users g        ON g.user_id     = b.guest_id
JOIN properties p   ON p.property_id = b.property_id
JOIN users h        ON h.user_id     = p.host_id
LEFT JOIN reviews r ON r.booking_id  = b.booking_id
ORDER BY b.booking_id;

-- (JOIN + агрегация): хосты с количеством объектов и суммарной выручкой
SELECT
    h.first_name || ' ' || h.last_name AS host_name,
    COUNT(DISTINCT p.property_id)       AS properties_count,
    COUNT(b.booking_id)                 AS bookings_count,
    COALESCE(SUM(b.total_price), 0)     AS total_revenue
FROM users h
JOIN properties p    ON p.host_id     = h.user_id
LEFT JOIN bookings b ON b.property_id = p.property_id
    AND b.status IN ('completed', 'confirmed')
GROUP BY h.user_id, h.first_name, h.last_name
ORDER BY total_revenue DESC;
