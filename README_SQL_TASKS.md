# Практика SQL по проекту DB_lessons

Задачи привязаны к схеме мини-сервиса бронирования жилья:

- `users(user_id, email, first_name, last_name, role, is_verified, ...)`;
- `property_types(type_id, name, description)`;
- `properties(property_id, host_id, type_id, title, city, country, price_per_night, max_guests, ...)`;
- `bookings(booking_id, guest_id, property_id, check_in_date, check_out_date, total_price, status, ...)`;
- `reviews(review_id, booking_id, rating, comment, ...)`.

Перед практикой можно выполнить:

```sql
\i lab2/01_ddl.sql
\i lab2/02_seed.sql
```

## 1. Простые SELECT

### Задача 1. Вывести все активные объекты жилья в Испании

```sql
SELECT property_id, title, city, price_per_night
FROM properties
WHERE country = 'Spain'
  AND is_active = TRUE
ORDER BY price_per_night DESC;
```

### Задача 2. Найти уникальные страны и города

```sql
SELECT DISTINCT country, city
FROM properties
ORDER BY country, city;
```

### Задача 3. Вывести жилье дешевле 100 за ночь и вместимостью минимум 2 гостя

```sql
SELECT title, city, price_per_night, max_guests
FROM properties
WHERE price_per_night < 100
  AND max_guests >= 2
ORDER BY price_per_night;
```

### Задача 4. Найти пользователей без телефона

```sql
SELECT user_id, email, first_name, last_name
FROM users
WHERE phone IS NULL;
```

### Задача 5. Вывести имя пользователя и телефон, заменив NULL на текст

```sql
SELECT
    user_id,
    first_name || ' ' || last_name AS full_name,
    COALESCE(phone, 'phone not specified') AS phone
FROM users
ORDER BY user_id;
```

## 2. INSERT, UPDATE, DELETE

### Задача 6. Добавить нового гостя

```sql
INSERT INTO users (email, password_hash, first_name, last_name, phone, role, is_verified)
VALUES ('alex.ivanov@email.com', 'hash_123', 'Alex', 'Ivanov', '+79990000000', 'guest', TRUE)
RETURNING user_id, email, role;
```

### Задача 7. Добавить бронирование через подзапросы

```sql
INSERT INTO bookings (guest_id, property_id, check_in_date, check_out_date, total_price, status)
VALUES (
    (SELECT user_id FROM users WHERE email = 'sarah.davis@email.com'),
    (SELECT property_id FROM properties WHERE title = 'Modern Apartment in Mitte'),
    DATE '2026-07-01',
    DATE '2026-07-04',
    3 * (SELECT price_per_night FROM properties WHERE title = 'Modern Apartment in Mitte'),
    'pending'
)
RETURNING *;
```

### Задача 8. Подтвердить все pending-бронирования, созданные до 1 мая 2026

```sql
UPDATE bookings
SET status = 'confirmed'
WHERE status = 'pending'
  AND created_at < TIMESTAMP '2026-05-01 00:00:00'
RETURNING booking_id, status, created_at;
```

### Задача 9. Деактивировать жилье без бронирований

```sql
UPDATE properties p
SET is_active = FALSE
WHERE NOT EXISTS (
    SELECT 1
    FROM bookings b
    WHERE b.property_id = p.property_id
)
RETURNING property_id, title, is_active;
```

### Задача 10. Удалить отзывы с рейтингом 1

```sql
DELETE FROM reviews
WHERE rating = 1
RETURNING review_id, rating, comment;
```

## 3. Агрегация и GROUP BY

### Задача 11. Посчитать количество объектов по городам

```sql
SELECT city, country, COUNT(*) AS property_count
FROM properties
GROUP BY city, country
ORDER BY property_count DESC, city;
```

### Задача 12. Найти среднюю цену жилья по типам

```sql
SELECT
    pt.name AS property_type,
    ROUND(AVG(p.price_per_night), 2) AS avg_price,
    MIN(p.price_per_night) AS min_price,
    MAX(p.price_per_night) AS max_price
FROM properties p
JOIN property_types pt ON pt.type_id = p.type_id
GROUP BY pt.name
ORDER BY avg_price DESC;
```

### Задача 13. Выручка по статусам бронирования

```sql
SELECT
    status,
    COUNT(*) AS booking_count,
    SUM(total_price) AS total_revenue,
    ROUND(AVG(total_price), 2) AS avg_booking_price
FROM bookings
GROUP BY status
ORDER BY total_revenue DESC NULLS LAST;
```

### Задача 14. Города с выручкой больше 1000 только по завершенным броням

```sql
SELECT
    p.city,
    p.country,
    SUM(b.total_price) AS completed_revenue
FROM bookings b
JOIN properties p ON p.property_id = b.property_id
WHERE b.status = 'completed'
GROUP BY p.city, p.country
HAVING SUM(b.total_price) > 1000
ORDER BY completed_revenue DESC;
```

### Задача 15. Количество отзывов и средний рейтинг по каждому объекту

```sql
SELECT
    p.property_id,
    p.title,
    COUNT(r.review_id) AS review_count,
    ROUND(AVG(r.rating), 2) AS avg_rating
FROM properties p
LEFT JOIN bookings b ON b.property_id = p.property_id
LEFT JOIN reviews r ON r.booking_id = b.booking_id
GROUP BY p.property_id, p.title
ORDER BY avg_rating DESC NULLS LAST, review_count DESC;
```

## 4. JOIN

### Задача 16. Вывести бронирования с гостем и объектом

```sql
SELECT
    b.booking_id,
    g.first_name || ' ' || g.last_name AS guest_name,
    p.title AS property_title,
    p.city,
    b.check_in_date,
    b.check_out_date,
    b.status,
    b.total_price
FROM bookings b
JOIN users g ON g.user_id = b.guest_id
JOIN properties p ON p.property_id = b.property_id
ORDER BY b.check_in_date;
```

### Задача 17. Все объекты и количество броней, включая объекты без броней

```sql
SELECT
    p.property_id,
    p.title,
    COUNT(b.booking_id) AS booking_count
FROM properties p
LEFT JOIN bookings b ON b.property_id = p.property_id
GROUP BY p.property_id, p.title
ORDER BY booking_count DESC, p.title;
```

### Задача 18. Хозяева и их суммарная выручка

```sql
SELECT
    h.user_id AS host_id,
    h.first_name || ' ' || h.last_name AS host_name,
    COUNT(DISTINCT p.property_id) AS properties_count,
    COALESCE(SUM(b.total_price) FILTER (WHERE b.status IN ('completed', 'confirmed')), 0) AS revenue
FROM users h
JOIN properties p ON p.host_id = h.user_id
LEFT JOIN bookings b ON b.property_id = p.property_id
WHERE h.role IN ('host', 'both')
GROUP BY h.user_id, h.first_name, h.last_name
ORDER BY revenue DESC;
```

### Задача 19. Найти гостей, которые еще не оставляли отзывы

```sql
SELECT DISTINCT
    u.user_id,
    u.email,
    u.first_name,
    u.last_name
FROM users u
JOIN bookings b ON b.guest_id = u.user_id
LEFT JOIN reviews r ON r.booking_id = b.booking_id
WHERE u.role IN ('guest', 'both')
  AND r.review_id IS NULL
ORDER BY u.user_id;
```

### Задача 20. CROSS JOIN: сгенерировать пары городов и типов жилья

```sql
SELECT c.city, pt.name AS property_type
FROM (SELECT DISTINCT city FROM properties) c
CROSS JOIN property_types pt
ORDER BY c.city, pt.name;
```

## 5. Подзапросы и EXISTS

### Задача 21. Найти жилье дороже средней цены

```sql
SELECT property_id, title, city, price_per_night
FROM properties
WHERE price_per_night > (
    SELECT AVG(price_per_night)
    FROM properties
)
ORDER BY price_per_night DESC;
```

### Задача 22. Найти объекты, у которых есть завершенные бронирования

```sql
SELECT p.property_id, p.title
FROM properties p
WHERE EXISTS (
    SELECT 1
    FROM bookings b
    WHERE b.property_id = p.property_id
      AND b.status = 'completed'
)
ORDER BY p.property_id;
```

### Задача 23. Найти пользователей, которые никогда не бронировали

```sql
SELECT u.user_id, u.email, u.role
FROM users u
WHERE NOT EXISTS (
    SELECT 1
    FROM bookings b
    WHERE b.guest_id = u.user_id
)
ORDER BY u.user_id;
```

### Задача 24. Найти самые дорогие объекты в каждой стране

```sql
SELECT p.property_id, p.title, p.country, p.price_per_night
FROM properties p
WHERE p.price_per_night = (
    SELECT MAX(p2.price_per_night)
    FROM properties p2
    WHERE p2.country = p.country
)
ORDER BY p.country;
```

## 6. Оконные функции

### Задача 25. Пронумеровать бронирования каждого гостя по дате создания

```sql
SELECT
    booking_id,
    guest_id,
    created_at,
    ROW_NUMBER() OVER (PARTITION BY guest_id ORDER BY created_at) AS booking_number_for_guest
FROM bookings
ORDER BY guest_id, created_at;
```

### Задача 26. Рейтинг объектов внутри города по цене

```sql
SELECT
    property_id,
    title,
    city,
    price_per_night,
    DENSE_RANK() OVER (PARTITION BY city ORDER BY price_per_night DESC) AS price_rank_in_city
FROM properties
ORDER BY city, price_rank_in_city;
```

### Задача 27. Доля бронирования в общей выручке

```sql
SELECT
    booking_id,
    total_price,
    ROUND(total_price / SUM(total_price) OVER () * 100, 2) AS percent_of_total
FROM bookings
ORDER BY percent_of_total DESC;
```

## 7. CTE

### Задача 28. Через CTE посчитать выручку хостов и оставить только топ-3

```sql
WITH host_revenue AS (
    SELECT
        h.user_id,
        h.email,
        SUM(b.total_price) FILTER (WHERE b.status IN ('completed', 'confirmed')) AS revenue
    FROM users h
    JOIN properties p ON p.host_id = h.user_id
    LEFT JOIN bookings b ON b.property_id = p.property_id
    GROUP BY h.user_id, h.email
)
SELECT user_id, email, COALESCE(revenue, 0) AS revenue
FROM host_revenue
ORDER BY revenue DESC NULLS LAST
LIMIT 3;
```

### Задача 29. CTE + UPDATE: поднять цену на 10% объектам с рейтингом 5

```sql
WITH top_rated_properties AS (
    SELECT p.property_id
    FROM properties p
    JOIN bookings b ON b.property_id = p.property_id
    JOIN reviews r ON r.booking_id = b.booking_id
    GROUP BY p.property_id
    HAVING AVG(r.rating) = 5
)
UPDATE properties p
SET price_per_night = ROUND((p.price_per_night * 1.10)::NUMERIC, 2)
FROM top_rated_properties trp
WHERE trp.property_id = p.property_id
RETURNING p.property_id, p.title, p.price_per_night;
```

## 8. NULL, CASE, FILTER

### Задача 30. Категоризировать жилье по цене

```sql
SELECT
    title,
    price_per_night,
    CASE
        WHEN price_per_night < 80 THEN 'budget'
        WHEN price_per_night < 180 THEN 'standard'
        ELSE 'premium'
    END AS price_category
FROM properties
ORDER BY price_per_night;
```

### Задача 31. Посчитать брони разных статусов одной строкой

```sql
SELECT
    COUNT(*) AS total_bookings,
    COUNT(*) FILTER (WHERE status = 'completed') AS completed_count,
    COUNT(*) FILTER (WHERE status = 'confirmed') AS confirmed_count,
    COUNT(*) FILTER (WHERE status = 'pending') AS pending_count,
    COUNT(*) FILTER (WHERE status = 'cancelled') AS cancelled_count
FROM bookings;
```

### Задача 32. Цена за ночь из бронирования с защитой от деления на ноль

```sql
SELECT
    booking_id,
    total_price,
    check_out_date - check_in_date AS nights,
    total_price / NULLIF(check_out_date - check_in_date, 0) AS price_per_night_fact
FROM bookings
ORDER BY booking_id;
```

## 9. Представления

### Задача 33. Создать view со сводкой объектов

```sql
CREATE OR REPLACE VIEW v_exam_property_summary AS
SELECT
    p.property_id,
    p.title,
    p.city,
    pt.name AS type_name,
    h.email AS host_email,
    COUNT(DISTINCT b.booking_id) AS total_bookings,
    ROUND(AVG(r.rating), 2) AS avg_rating
FROM properties p
JOIN property_types pt ON pt.type_id = p.type_id
JOIN users h ON h.user_id = p.host_id
LEFT JOIN bookings b ON b.property_id = p.property_id
LEFT JOIN reviews r ON r.booking_id = b.booking_id
GROUP BY p.property_id, p.title, p.city, pt.name, h.email;

SELECT *
FROM v_exam_property_summary
ORDER BY total_bookings DESC;
```

### Задача 34. Материализованное представление по выручке городов

```sql
CREATE MATERIALIZED VIEW mv_exam_city_revenue AS
SELECT
    p.city,
    p.country,
    SUM(b.total_price) AS revenue
FROM bookings b
JOIN properties p ON p.property_id = b.property_id
WHERE b.status IN ('completed', 'confirmed')
GROUP BY p.city, p.country;

SELECT * FROM mv_exam_city_revenue ORDER BY revenue DESC;

REFRESH MATERIALIZED VIEW mv_exam_city_revenue;
```

## 10. Индексы и EXPLAIN

### Задача 35. Индекс для поиска броней по статусу и дате

```sql
CREATE INDEX IF NOT EXISTS idx_exam_bookings_status_checkin
ON bookings(status, check_in_date);

EXPLAIN ANALYZE
SELECT booking_id, guest_id, property_id, check_in_date
FROM bookings
WHERE status = 'confirmed'
  AND check_in_date >= DATE '2026-05-01';
```

### Задача 36. Частичный индекс только для активных подтвержденных броней

```sql
CREATE INDEX IF NOT EXISTS idx_exam_confirmed_bookings_property_date
ON bookings(property_id, check_in_date, check_out_date)
WHERE status = 'confirmed';
```

### Задача 37. Индекс на выражение для поиска email без учета регистра

```sql
CREATE INDEX IF NOT EXISTS idx_exam_users_lower_email
ON users (LOWER(email));

EXPLAIN ANALYZE
SELECT *
FROM users
WHERE LOWER(email) = LOWER('SARAH.DAVIS@email.com');
```

## 11. Транзакции

### Задача 38. Создать бронь и отзыв в одной транзакции

```sql
BEGIN;

INSERT INTO bookings (guest_id, property_id, check_in_date, check_out_date, total_price, status)
VALUES (4, 1, DATE '2026-08-01', DATE '2026-08-03', 190.00, 'completed')
RETURNING booking_id;

-- Подставить booking_id из предыдущего INSERT.
INSERT INTO reviews (booking_id, rating, comment)
VALUES (currval('bookings_booking_id_seq'), 5, 'Great stay');

COMMIT;
```

### Задача 39. SAVEPOINT: откатить только неудачный отзыв

```sql
BEGIN;

INSERT INTO bookings (guest_id, property_id, check_in_date, check_out_date, total_price, status)
VALUES (6, 6, DATE '2026-09-01', DATE '2026-09-04', 180.00, 'completed');

SAVEPOINT before_review;

-- Ошибка: рейтинг вне диапазона 1..5.
INSERT INTO reviews (booking_id, rating, comment)
VALUES (currval('bookings_booking_id_seq'), 9, 'Invalid rating');

ROLLBACK TO SAVEPOINT before_review;

INSERT INTO reviews (booking_id, rating, comment)
VALUES (currval('bookings_booking_id_seq'), 4, 'Corrected rating');

COMMIT;
```

### Задача 40. Заблокировать строку объекта перед изменением цены

```sql
BEGIN;

SELECT property_id, price_per_night
FROM properties
WHERE property_id = 1
FOR UPDATE;

UPDATE properties
SET price_per_night = price_per_night + 10
WHERE property_id = 1;

COMMIT;
```

## 12. Функции, процедуры, триггеры

Перед задачами можно выполнить:

```sql
\i lab3/01_procedures_functions.sql
\i lab3/02_triggers.sql
```

### Задача 41. Проверить существование активного объекта

```sql
SELECT property_exists(1) AS exists_property_1,
       property_exists(999) AS exists_property_999;
```

### Задача 42. Получить статистику бронирований пользователя

```sql
SELECT *
FROM check_user_booking_activity(4);
```

### Задача 43. Создать бронь через процедуру с проверками

```sql
CALL add_booking_with_validation(
    4,
    6,
    DATE '2026-12-01',
    DATE '2026-12-05'
);
```

### Задача 44. Проверить аудит изменения статуса

```sql
UPDATE bookings
SET status = 'cancelled'
WHERE booking_id = 8;

SELECT *
FROM booking_audit
WHERE booking_id = 8
ORDER BY changed_at DESC;
```

### Задача 45. Проверить триггер пересечения дат

```sql
-- Должна быть ошибка, если для объекта 1 уже есть pending/confirmed бронь на эти даты.
INSERT INTO bookings (guest_id, property_id, check_in_date, check_out_date, total_price, status)
VALUES (4, 1, DATE '2026-05-12', DATE '2026-05-14', 190.00, 'pending');
```

## 13. JSONB

В базовой схеме JSONB-поля нет, поэтому это экзаменационное расширение.

### Задача 46. Добавить JSONB-характеристики объекта

```sql
ALTER TABLE properties
ADD COLUMN IF NOT EXISTS specs JSONB NOT NULL DEFAULT '{}'::jsonb;

UPDATE properties
SET specs = jsonb_build_object(
    'color', 'white',
    'weight', 12,
    'size', jsonb_build_object('width', 40, 'height', 30),
    'amenities', jsonb_build_array('wifi', 'kitchen')
)
WHERE property_id = 1;
```

### Задача 47. Фильтрация по JSONB

```sql
SELECT property_id, title, specs ->> 'color' AS color
FROM properties
WHERE specs @> '{"color":"white"}';
```

### Задача 48. Проверить наличие ключа и достать вложенное поле

```sql
SELECT
    property_id,
    title,
    specs ? 'size' AS has_size,
    specs -> 'size' ->> 'width' AS width
FROM properties
WHERE specs ? 'size';
```

### Задача 49. GIN-индекс для JSONB

```sql
CREATE INDEX IF NOT EXISTS idx_exam_properties_specs_gin
ON properties USING GIN (specs);

EXPLAIN ANALYZE
SELECT *
FROM properties
WHERE specs @> '{"amenities":["wifi"]}';
```

## 14. Массивы

### Задача 50. Добавить массив тегов

```sql
ALTER TABLE properties
ADD COLUMN IF NOT EXISTS tags TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];

UPDATE properties
SET tags = ARRAY['wifi', 'center', 'family']
WHERE property_id = 1;
```

### Задача 51. Найти объекты с тегом wifi

```sql
SELECT property_id, title, tags
FROM properties
WHERE tags @> ARRAY['wifi'];
```

### Задача 52. Развернуть массив тегов в строки

```sql
SELECT
    p.property_id,
    p.title,
    tag
FROM properties p
CROSS JOIN LATERAL unnest(p.tags) AS tag
ORDER BY p.property_id, tag;
```

### Задача 53. GIN-индекс на массив

```sql
CREATE INDEX IF NOT EXISTS idx_exam_properties_tags_gin
ON properties USING GIN (tags);
```

## 15. M:M через промежуточную таблицу

### Задача 54. Создать удобства и связать их с жильем

```sql
CREATE TABLE IF NOT EXISTS amenities (
    amenity_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS property_amenities (
    property_id INTEGER NOT NULL REFERENCES properties(property_id) ON DELETE CASCADE,
    amenity_id INTEGER NOT NULL REFERENCES amenities(amenity_id) ON DELETE CASCADE,
    PRIMARY KEY (property_id, amenity_id)
);

INSERT INTO amenities (name)
VALUES ('wifi'), ('parking'), ('pool')
ON CONFLICT (name) DO NOTHING;

INSERT INTO property_amenities (property_id, amenity_id)
SELECT 1, amenity_id
FROM amenities
WHERE name IN ('wifi', 'parking')
ON CONFLICT DO NOTHING;
```

### Задача 55. Найти объекты, где есть wifi и parking

```sql
SELECT p.property_id, p.title
FROM properties p
JOIN property_amenities pa ON pa.property_id = p.property_id
JOIN amenities a ON a.amenity_id = pa.amenity_id
WHERE a.name IN ('wifi', 'parking')
GROUP BY p.property_id, p.title
HAVING COUNT(DISTINCT a.name) = 2;
```

## 16. Удаление дубликатов

### Задача 56. Показать потенциальные дубли пользователей по email

```sql
SELECT email, COUNT(*) AS cnt
FROM users
GROUP BY email
HAVING COUNT(*) > 1;
```

### Задача 57. Удалить дубли, оставив строку с минимальным user_id

```sql
WITH duplicates AS (
    SELECT
        user_id,
        ROW_NUMBER() OVER (PARTITION BY email ORDER BY user_id) AS rn
    FROM users
)
DELETE FROM users u
USING duplicates d
WHERE u.user_id = d.user_id
  AND d.rn > 1;
```

На текущей схеме `users.email` имеет `UNIQUE`, поэтому реальные дубли email вставить нельзя. Эта задача показывает общий прием.

## 17. Реляционная алгебра в SQL

### Задача 58. UNION: города из Испании или Италии

```sql
SELECT city FROM properties WHERE country = 'Spain'
UNION
SELECT city FROM properties WHERE country = 'Italy';
```

### Задача 59. INTERSECT: пользователи, которые могут быть гостями и уже бронировали

```sql
SELECT user_id FROM users WHERE role IN ('guest', 'both')
INTERSECT
SELECT guest_id FROM bookings;
```

### Задача 60. EXCEPT: пользователи-гости без бронирований

```sql
SELECT user_id FROM users WHERE role IN ('guest', 'both')
EXCEPT
SELECT guest_id FROM bookings;
```

## 18. Мини-вопросы, которые могут дать на тесте

### Написать запрос: "Топ-5 объектов по выручке"

```sql
SELECT
    p.property_id,
    p.title,
    SUM(b.total_price) AS revenue
FROM properties p
JOIN bookings b ON b.property_id = p.property_id
WHERE b.status IN ('completed', 'confirmed')
GROUP BY p.property_id, p.title
ORDER BY revenue DESC
LIMIT 5;
```

### Написать запрос: "Объекты без отзывов"

```sql
SELECT p.property_id, p.title
FROM properties p
LEFT JOIN bookings b ON b.property_id = p.property_id
LEFT JOIN reviews r ON r.booking_id = b.booking_id
GROUP BY p.property_id, p.title
HAVING COUNT(r.review_id) = 0;
```

### Написать запрос: "Средний рейтинг хозяина"

```sql
SELECT
    h.user_id,
    h.email,
    ROUND(AVG(r.rating), 2) AS avg_host_rating
FROM users h
JOIN properties p ON p.host_id = h.user_id
JOIN bookings b ON b.property_id = p.property_id
JOIN reviews r ON r.booking_id = b.booking_id
GROUP BY h.user_id, h.email
ORDER BY avg_host_rating DESC;
```

### Написать запрос: "Проверить свободен ли объект на даты"

```sql
SELECT NOT EXISTS (
    SELECT 1
    FROM bookings b
    WHERE b.property_id = 1
      AND b.status IN ('pending', 'confirmed')
      AND b.check_in_date < DATE '2026-07-10'
      AND b.check_out_date > DATE '2026-07-01'
) AS is_available;
```

Главное условие пересечения дат:

```sql
existing.check_in_date < new_check_out
AND existing.check_out_date > new_check_in
```

