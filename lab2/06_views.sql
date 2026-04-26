DROP VIEW IF EXISTS v_active_bookings;
DROP VIEW IF EXISTS v_host_revenue;
DROP VIEW IF EXISTS v_property_summary;

-- сводка по объектам (тип, хост, кол-во бронирований, средний рейтинг)
CREATE VIEW v_property_summary AS
SELECT
    p.property_id,
    p.title,
    pt.name                              AS property_type,
    u.first_name || ' ' || u.last_name   AS host_name,
    p.city,
    p.country,
    p.price_per_night,
    p.is_active,
    COUNT(DISTINCT b.booking_id)         AS total_bookings,
    COALESCE(ROUND(AVG(r.rating), 2), 0) AS avg_rating,
    MAX(b.check_in_date)                 AS last_check_in
FROM properties p
JOIN property_types pt  ON pt.type_id    = p.type_id
JOIN users u            ON u.user_id     = p.host_id
LEFT JOIN bookings b    ON b.property_id = p.property_id
LEFT JOIN reviews r     ON r.booking_id  = b.booking_id
GROUP BY
    p.property_id, p.title, pt.name,
    u.first_name, u.last_name,
    p.city, p.country, p.price_per_night, p.is_active;

-- финансовая статистика по хостам
CREATE VIEW v_host_revenue AS
SELECT
    u.user_id,
    u.first_name || ' ' || u.last_name        AS host_name,
    u.email,
    COUNT(DISTINCT p.property_id)             AS total_properties,
    COUNT(b.booking_id)                       AS total_bookings,
    COALESCE(SUM(b.total_price), 0)           AS total_revenue,
    COALESCE(ROUND(AVG(b.total_price), 2), 0) AS avg_booking_value,
    MAX(b.created_at)                         AS last_booking_date
FROM users u
JOIN properties p    ON p.host_id     = u.user_id
LEFT JOIN bookings b ON b.property_id = p.property_id
    AND b.status IN ('completed', 'confirmed')
GROUP BY u.user_id, u.first_name, u.last_name, u.email;

-- активные и предстоящие бронирования с полными деталями
CREATE VIEW v_active_bookings AS
SELECT
    b.booking_id,
    b.check_in_date,
    b.check_out_date,
    (b.check_out_date - b.check_in_date)     AS nights,
    b.total_price,
    b.status,
    g.first_name || ' ' || g.last_name       AS guest_name,
    g.email                                  AS guest_email,
    p.title                                  AS property_title,
    p.city,
    p.country,
    h.first_name || ' ' || h.last_name       AS host_name,
    h.email                                  AS host_email
FROM bookings b
JOIN users g       ON g.user_id     = b.guest_id
JOIN properties p  ON p.property_id = b.property_id
JOIN users h       ON h.user_id     = p.host_id
WHERE b.status IN ('pending', 'confirmed')
  AND b.check_out_date >= CURRENT_DATE;

-- просмотр результатов представлений
SELECT * FROM v_property_summary ORDER BY total_bookings DESC;
SELECT * FROM v_host_revenue     ORDER BY total_revenue DESC;
SELECT * FROM v_active_bookings  ORDER BY check_in_date;
