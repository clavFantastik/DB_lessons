-- регистрация нового гостя
INSERT INTO users (email, password_hash, first_name, last_name, phone, role, is_verified)
VALUES ('lucas.green@email.com', '$2b$12$kK1lL2mM3nN4oO5pP6qQ7u', 'Lucas', 'Green', '+447712345678', 'guest', TRUE);

-- новое бронирование от этого гостя (студия в Париже, 6 ночей)
INSERT INTO bookings (guest_id, property_id, check_in_date, check_out_date, total_price, status)
VALUES (
    (SELECT user_id FROM users WHERE email = 'lucas.green@email.com'),
    7,
    '2026-07-01',
    '2026-07-07',
    450.00,
    'confirmed'
);

-- подтверждение бронирования (pending -> confirmed)
UPDATE bookings
SET status = 'confirmed'
WHERE booking_id = 12;

-- верификация пользователя после подтверждения email
UPDATE users
SET is_verified = TRUE
WHERE user_id = 5;

-- повышение цены виллы на высокий сезон
UPDATE properties
SET price_per_night = 380.00
WHERE property_id = 8;

-- очистка отменённых бронирований
DELETE FROM bookings
WHERE status = 'cancelled';

-- гость отменяет своё бронирование
DELETE FROM bookings
WHERE guest_id = (SELECT user_id FROM users WHERE email = 'lucas.green@email.com');

-- гость удаляет аккаунт
DELETE FROM users
WHERE email = 'lucas.green@email.com';
