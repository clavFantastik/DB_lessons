-- суммарная выручка и количество бронирований по каждому хосту
SELECT
    u.first_name || ' ' || u.last_name AS host_name,
    COUNT(b.booking_id)                AS total_bookings,
    SUM(b.total_price)                 AS total_revenue,
    ROUND(AVG(b.total_price), 2)       AS avg_booking_value
FROM users u
JOIN properties p ON p.host_id = u.user_id
JOIN bookings b   ON b.property_id = p.property_id
WHERE b.status IN ('completed', 'confirmed')
GROUP BY u.user_id, u.first_name, u.last_name
ORDER BY total_revenue DESC;

-- средний рейтинг объектов с фильтрацией через HAVING (только >= 3 звёзд)
SELECT
    p.title,
    p.city,
    COUNT(r.review_id)      AS review_count,
    MIN(r.rating)           AS min_rating,
    MAX(r.rating)           AS max_rating,
    ROUND(AVG(r.rating), 2) AS avg_rating
FROM properties p
JOIN bookings b ON b.property_id = p.property_id
JOIN reviews r  ON r.booking_id  = b.booking_id
GROUP BY p.property_id, p.title, p.city
HAVING AVG(r.rating) >= 3
ORDER BY avg_rating DESC;

-- количество и сумма бронирований по статусам
SELECT
    status,
    COUNT(*)                   AS booking_count,
    SUM(total_price)           AS total_value,
    ROUND(AVG(total_price), 2) AS avg_value
FROM bookings
GROUP BY status
ORDER BY booking_count DESC;

-- минимальная, максимальная и средняя цена за ночь по странам
SELECT
    country,
    COUNT(*)                       AS property_count,
    MIN(price_per_night)           AS min_price,
    MAX(price_per_night)           AS max_price,
    ROUND(AVG(price_per_night), 2) AS avg_price
FROM properties
WHERE is_active = TRUE
GROUP BY country
ORDER BY avg_price DESC;

-- топ объектов по выручке (только с 2+ бронированиями)
SELECT
    p.title,
    p.city,
    COUNT(b.booking_id)          AS bookings_count,
    SUM(b.total_price)           AS total_revenue,
    ROUND(AVG(b.total_price), 2) AS avg_booking_value
FROM properties p
JOIN bookings b ON b.property_id = p.property_id
WHERE b.status IN ('completed', 'confirmed')
GROUP BY p.property_id, p.title, p.city
HAVING COUNT(b.booking_id) >= 2
ORDER BY total_revenue DESC;
