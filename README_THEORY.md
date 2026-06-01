# Теория по базам данных

Шпаргалка составлена под PostgreSQL и проект с бронированием жилья: `users`, `properties`, `bookings`, `reviews`, `property_types`.

## 1. Основы баз данных

**База данных (БД)** - организованная совокупность данных, которые хранятся структурированно и доступны для поиска, изменения и анализа.

**СУБД** - система управления базами данных. Примеры: PostgreSQL, MySQL, SQLite, Oracle.

**Модель данных** - способ описания данных и связей между ними. Основные модели: реляционная, документная, графовая, ключ-значение.

Функции любой СУБД:

- хранение данных;
- создание и изменение структуры БД;
- добавление, изменение, удаление и чтение данных;
- поддержка целостности данных через ограничения;
- управление транзакциями;
- разграничение прав доступа;
- резервное копирование и восстановление;
- оптимизация запросов;
- параллельная работа пользователей.

## 2. Проектирование схемы БД

Типы связей:

- `1:1` - одной записи соответствует одна запись. Пример: `users` и `user_profiles`.
- `1:M` - одной записи соответствует много записей. Пример: один `users`-host имеет много `properties`.
- `M:M` - много записей связаны со многими. Пример: жилье и удобства: одно жилье имеет много удобств, одно удобство есть у многих объектов.

Реализация связей:

- первичный ключ (`PRIMARY KEY`) уникально определяет строку;
- внешний ключ (`FOREIGN KEY`) ссылается на первичный или уникальный ключ другой таблицы;
- связь `1:M` делается внешним ключом на стороне "многие";
- связь `M:M` обычно делается промежуточной таблицей.

Пример `M:M`:

```sql
CREATE TABLE amenities (
    amenity_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE property_amenities (
    property_id INTEGER NOT NULL REFERENCES properties(property_id),
    amenity_id INTEGER NOT NULL REFERENCES amenities(amenity_id),
    PRIMARY KEY (property_id, amenity_id)
);
```

Промежуточная таблица лучше JSON/массивов, когда нужны внешние ключи, JOIN, индексы и строгая целостность. JSON/массив удобнее для гибких атрибутов, которые редко участвуют в связях.

**Составной первичный ключ** - ключ из нескольких столбцов. В примере выше пара `(property_id, amenity_id)` запрещает дублировать одно удобство у одного объекта.

## 3. DDL

DDL - команды для структуры БД: `CREATE`, `ALTER`, `DROP`, `TRUNCATE`.

Создание таблицы:

```sql
CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    guest_id INTEGER NOT NULL REFERENCES users(user_id),
    property_id INTEGER NOT NULL REFERENCES properties(property_id),
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    total_price DECIMAL(10,2) NOT NULL CHECK (total_price > 0),
    CONSTRAINT chk_dates CHECK (check_out_date > check_in_date)
);
```

Ограничения:

- `PRIMARY KEY` - уникально идентифицирует строку, не допускает `NULL`;
- `UNIQUE` - запрещает повторы, но может допускать `NULL`;
- `NOT NULL` - значение обязательно;
- `CHECK` - проверяет условие;
- `FOREIGN KEY` - поддерживает ссылочную целостность.

`PRIMARY KEY` vs `UNIQUE NOT NULL`:

- оба запрещают дубли и `NULL`;
- `PRIMARY KEY` у таблицы обычно один и является главным идентификатором строки;
- `UNIQUE NOT NULL` может быть несколько, например `users.email`.

`ALTER TABLE`:

```sql
ALTER TABLE properties ADD COLUMN floor INTEGER;
ALTER TABLE properties ALTER COLUMN title TYPE VARCHAR(300);
ALTER TABLE properties ADD CONSTRAINT chk_floor CHECK (floor >= 0);
ALTER TABLE properties DROP COLUMN floor;
```

## 4. Нормализация и денормализация

**1НФ**: в ячейке одно атомарное значение, нет списков в одном поле.

Плохо: `phone = '+1,+2'`. Хорошо: отдельная таблица `user_phones`.

**2НФ**: таблица в 1НФ, и все неключевые поля зависят от всего составного ключа, а не от его части.

Плохо в `property_amenities(property_id, amenity_id, amenity_name)`: `amenity_name` зависит только от `amenity_id`. Лучше вынести в `amenities`.

**3НФ**: таблица в 2НФ, и нет транзитивных зависимостей между неключевыми полями.

Плохо: в `properties` хранить `host_email`, потому что он зависит от `host_id`, а не от `property_id`. Лучше брать email через JOIN с `users`.

**BCNF** строже 3НФ: любой детерминант должен быть потенциальным ключом. Отличие проявляется в сложных зависимостях, когда 3НФ формально выполнена, но остаются аномалии обновления.

**Денормализация** - намеренное добавление избыточности ради скорости чтения. Пример: хранить `avg_rating` и `total_reviews` в `property_stats`, хотя это можно считать из `reviews`. Минусы: риск рассинхронизации, сложнее обновлять данные, нужны триггеры или фоновые пересчеты.

## 5. DML

DML - команды работы с данными: `INSERT`, `UPDATE`, `DELETE`, `SELECT`.

```sql
INSERT INTO users (email, password_hash, first_name, last_name, role)
VALUES ('a@b.com', 'hash', 'Ann', 'Lee', 'guest');

UPDATE bookings
SET status = 'cancelled'
WHERE booking_id = 10;

DELETE FROM reviews
WHERE rating = 1;
```

Подзапрос в DML:

```sql
UPDATE bookings
SET status = 'cancelled'
WHERE guest_id = (SELECT user_id FROM users WHERE email = 'james.wilson@email.com');
```

Удаление дубликатов через `ROW_NUMBER()`:

```sql
DELETE FROM users u
USING (
    SELECT user_id,
           ROW_NUMBER() OVER (PARTITION BY email ORDER BY user_id) AS rn
    FROM users
) d
WHERE u.user_id = d.user_id
  AND d.rn > 1;
```

## 6. Операторы, операнды, NULL

Операнд - значение, над которым выполняется операция: столбец, константа, переменная, результат функции.

Операторы:

- арифметические: `+`, `-`, `*`, `/`;
- сравнения: `=`, `<>`, `>`, `<`, `>=`, `<=`;
- логические: `AND`, `OR`, `NOT`;
- строковые: `LIKE`, `ILIKE`, `||`;
- специальные: `IN`, `BETWEEN`, `IS NULL`, `EXISTS`.

`NULL` означает неизвестное или отсутствующее значение. Сравнение `= NULL` не работает, нужно `IS NULL`.

```sql
SELECT COALESCE(phone, 'no phone') FROM users;
SELECT total_price / NULLIF(check_out_date - check_in_date, 0) FROM bookings;
```

Агрегаты обычно игнорируют `NULL`: `AVG`, `SUM`, `MIN`, `MAX`. `COUNT(*)` считает строки, `COUNT(column)` считает не-NULL значения. Сортировка `NULL` управляется через `NULLS FIRST`/`NULLS LAST`.

## 7. SELECT

Логический порядок выполнения:

1. `FROM`
2. `JOIN`
3. `WHERE`
4. `GROUP BY`
5. агрегатные функции
6. `HAVING`
7. `SELECT`
8. `DISTINCT`
9. `ORDER BY`
10. `LIMIT`/`OFFSET`

Полный пример:

```sql
SELECT p.city, COUNT(*) AS bookings_count, SUM(b.total_price) AS revenue
FROM bookings b
JOIN properties p ON p.property_id = b.property_id
WHERE b.status = 'completed'
GROUP BY p.city
HAVING COUNT(*) >= 2
ORDER BY revenue DESC
LIMIT 10;
```

`WHERE` фильтрует строки до группировки. `HAVING` фильтрует группы после `GROUP BY`.

`DISTINCT` убирает дубликаты:

```sql
SELECT DISTINCT city, country FROM properties;
```

## 8. JOIN

Типы JOIN:

- `INNER JOIN` - только совпавшие строки из обеих таблиц;
- `LEFT JOIN` - все строки слева и совпадения справа, иначе `NULL`;
- `RIGHT JOIN` - все строки справа и совпадения слева;
- `FULL JOIN` - все строки из обеих таблиц;
- `CROSS JOIN` - декартово произведение.

Условные диаграммы Венна:

- `INNER` = пересечение A и B;
- `LEFT` = весь A + совпавшая часть B;
- `RIGHT` = весь B + совпавшая часть A;
- `FULL` = A объединить с B;
- `CROSS` = каждая строка A с каждой строкой B.

Когда использовать:

- `INNER` - нужны только связанные данные;
- `LEFT` - нужно сохранить все строки основной таблицы, например все объекты даже без отзывов;
- `FULL` - поиск несовпадений с обеих сторон;
- `CROSS` - генерация комбинаций.

JOIN отличается от декартова произведения тем, что JOIN обычно имеет условие `ON`, которое связывает строки. Без условия получится слишком много лишних комбинаций.

## 9. Подзапросы

Обычный подзапрос выполняется независимо:

```sql
SELECT *
FROM properties
WHERE price_per_night > (SELECT AVG(price_per_night) FROM properties);
```

Коррелированный подзапрос зависит от внешней строки:

```sql
SELECT p.*
FROM properties p
WHERE EXISTS (
    SELECT 1
    FROM bookings b
    WHERE b.property_id = p.property_id
);
```

JOIN часто удобнее и быстрее для массового соединения таблиц. Подзапросы удобны для проверок `EXISTS`, одиночных значений и логики "есть/нет". В PostgreSQL оптимизатор часто преобразует подзапросы в похожие планы, поэтому надо смотреть `EXPLAIN`.

## 10. Транзакции и ACID

Транзакция - набор операций, который выполняется как единое целое.

ACID:

- Atomicity - все операции или ни одной;
- Consistency - после транзакции данные не нарушают ограничения;
- Isolation - параллельные транзакции не ломают друг друга;
- Durability - после `COMMIT` данные сохранены.

Уровни изоляции:

- `Read Uncommitted` - допускает грязные чтения, в PostgreSQL фактически работает как `Read Committed`;
- `Read Committed` - видны только зафиксированные данные, но повторное чтение может измениться;
- `Repeatable Read` - транзакция видит стабильный снимок данных;
- `Serializable` - максимально строгий уровень, результат как при последовательном выполнении.

Аномалии:

- грязное чтение - прочитали незакоммиченные данные;
- неповторяющееся чтение - одна строка при повторном чтении изменилась;
- фантом - при повторном запросе появились новые строки.

`SAVEPOINT`:

```sql
BEGIN;
INSERT INTO bookings (...);
SAVEPOINT before_review;
INSERT INTO reviews (...);
ROLLBACK TO SAVEPOINT before_review;
COMMIT;
```

**MVCC** в PostgreSQL - механизм версий строк. Читатели не блокируют писателей: транзакция видит подходящую версию строки согласно своему снимку.

## 11. Внешние ключи

Внешние ключи поддерживают ссылочную целостность.

Действия при удалении/обновлении родителя:

- `CASCADE` - удалить/обновить зависимые строки;
- `RESTRICT`/`NO ACTION` - запретить действие, если есть ссылки;
- `SET NULL` - поставить `NULL` в дочерних строках;
- `SET DEFAULT` - поставить значение по умолчанию.

В проекте:

```sql
booking_id INTEGER NOT NULL UNIQUE
REFERENCES bookings(booking_id) ON DELETE CASCADE
```

Если удалить бронь, ее отзыв удалится автоматически.

## 12. Индексирование

Индекс ускоряет поиск, сортировку и соединения, но замедляет вставку/обновление и занимает место.

Виды:

- `B-tree` - стандартный индекс для `=`, диапазонов, сортировки;
- `Hash` - для равенства, используется реже;
- `GIN` - массивы, `jsonb`, полнотекстовый поиск, триграммы;
- `GiST` - геоданные, диапазоны, полнотекстовый поиск, расширяемые структуры.

Когда индекс не используется:

- таблица маленькая, дешевле `Seq Scan`;
- условие возвращает большую часть таблицы;
- функция над столбцом мешает обычному индексу: `LOWER(email)`;
- типы не совпадают;
- составной индекс используется не с левого префикса;
- статистика устарела.

Частичный индекс:

```sql
CREATE INDEX idx_confirmed_bookings
ON bookings(property_id, check_in_date)
WHERE status = 'confirmed';
```

Индекс на выражение:

```sql
CREATE INDEX idx_users_lower_email ON users (LOWER(email));
```

Составной индекс:

```sql
CREATE INDEX idx_bookings_status_date ON bookings(status, check_in_date);
```

Порядок столбцов важен: сначала обычно ставят более селективные или часто фильтруемые поля.

## 13. Оптимизация и EXPLAIN

`EXPLAIN` показывает план запроса, `EXPLAIN ANALYZE` реально выполняет запрос и показывает фактическое время.

```sql
EXPLAIN ANALYZE
SELECT *
FROM bookings
WHERE status = 'confirmed'
  AND check_in_date >= DATE '2026-05-01';
```

Признаки тормозящего запроса:

- большой `Seq Scan` по крупной таблице;
- много строк отфильтровывается после чтения;
- дорогая сортировка `Sort`;
- тяжелый `Nested Loop` на больших объемах;
- фактические строки сильно отличаются от оценок.

Индексы в плане видны как `Index Scan`, `Index Only Scan`, `Bitmap Index Scan`.

## 14. JSON в PostgreSQL

`json` хранит текст JSON, `jsonb` хранит разобранный бинарный формат. Обычно для запросов лучше `jsonb`: быстрее фильтрация, есть индексы GIN.

Операторы:

- `->` получить JSON-значение;
- `->>` получить текст;
- `@>` проверка "содержит";
- `?` проверка наличия ключа.

Пример:

```sql
ALTER TABLE properties ADD COLUMN specs JSONB;

UPDATE properties
SET specs = '{"color":"white","weight":12,"size":{"width":40,"height":30}}';

SELECT title
FROM properties
WHERE specs @> '{"color":"white"}';

CREATE INDEX idx_properties_specs_gin ON properties USING GIN (specs);
```

JSON-поле подходит для гибких характеристик товара/объекта: цвет, вес, размеры, правила дома. Но основные связи и обязательные поля лучше хранить отдельными колонками.

## 15. Массивы

Массив хранит список значений одного типа:

```sql
ALTER TABLE properties ADD COLUMN tags TEXT[];

UPDATE properties
SET tags = ARRAY['wifi', 'central', 'family'];

SELECT *
FROM properties
WHERE tags @> ARRAY['wifi'];
```

Массивы можно индексировать GIN:

```sql
CREATE INDEX idx_properties_tags_gin ON properties USING GIN (tags);
```

Для связи `M:M` массив хуже промежуточной таблицы: нет нормальных внешних ключей на каждый элемент, сложнее хранить атрибуты связи и поддерживать целостность.

## 16. Представления

View - сохраненный SQL-запрос.

```sql
CREATE VIEW v_active_bookings AS
SELECT *
FROM bookings
WHERE status IN ('pending', 'confirmed');

DROP VIEW v_active_bookings;
```

Обычное представление не хранит данные, оно выполняет запрос при обращении.

Материализованное представление хранит результат физически:

```sql
CREATE MATERIALIZED VIEW mv_city_revenue AS
SELECT p.city, SUM(b.total_price) AS revenue
FROM bookings b
JOIN properties p ON p.property_id = b.property_id
GROUP BY p.city;

REFRESH MATERIALIZED VIEW mv_city_revenue;
```

Плюс - быстрее чтение. Минус - данные надо обновлять.

## 17. Хранимые процедуры и функции

Функция возвращает значение и может использоваться в `SELECT`. Процедура вызывается через `CALL` и больше подходит для бизнес-операций.

Функция:

```sql
CREATE FUNCTION property_exists(p_property_id INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM properties
        WHERE property_id = p_property_id AND is_active = TRUE
    );
END;
$$ LANGUAGE plpgsql;
```

Функция, возвращающая таблицу:

```sql
CREATE FUNCTION check_user_booking_activity(p_user_id INTEGER)
RETURNS TABLE(total_bookings INTEGER, total_spent DECIMAL) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(*)::INTEGER, COALESCE(SUM(total_price), 0)
    FROM bookings
    WHERE guest_id = p_user_id;
END;
$$ LANGUAGE plpgsql;
```

Процедура добавления брони + логирование обычно делает проверки, вставляет бронь и пишет строку в audit-таблицу.

## 18. Триггеры

Триггер автоматически запускает функцию при событии таблицы.

Виды:

- `BEFORE` - до операции, можно проверить/изменить `NEW`;
- `AFTER` - после операции, удобно для аудита;
- `INSTEAD OF` - вместо операции, обычно для view.

Пример проверки, что новая цена не меньше старой:

```sql
CREATE FUNCTION trg_fn_salary_not_decrease()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.salary < OLD.salary THEN
        RAISE EXCEPTION 'New salary cannot be lower than old salary';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

Аудит через триггер: при `INSERT`/`UPDATE`/`DELETE` записывать старые и новые значения в лог-таблицу. В проекте есть аудит статусов бронирований через `booking_audit`.

Вложенные вызовы возможны: один триггер может изменить таблицу, на которой тоже есть триггер. Это надо контролировать, чтобы не получить бесконечную рекурсию.

## 19. Реляционная алгебра

Основные операции:

- ограничение, selection `σ` - фильтрация строк, SQL: `WHERE`;
- проекция `π` - выбор столбцов, SQL: `SELECT column`;
- объединение `∪` - SQL: `UNION`;
- пересечение `∩` - SQL: `INTERSECT`;
- разность `−` - SQL: `EXCEPT`;
- соединение `⋈` - SQL: `JOIN`;
- декартово произведение `×` - SQL: `CROSS JOIN`.

Примеры:

```sql
-- Ограничение
SELECT * FROM bookings WHERE status = 'confirmed';

-- Проекция
SELECT email, role FROM users;

-- Объединение
SELECT city FROM properties WHERE country = 'Spain'
UNION
SELECT city FROM properties WHERE country = 'Italy';

-- Пересечение
SELECT user_id FROM users WHERE role IN ('guest', 'both')
INTERSECT
SELECT guest_id FROM bookings;

-- Разность
SELECT user_id FROM users
EXCEPT
SELECT guest_id FROM bookings;
```

