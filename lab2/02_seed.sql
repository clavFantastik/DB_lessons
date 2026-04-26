INSERT INTO property_types (name, description) VALUES
    ('Apartment', 'Entire apartment'),
    ('House',     'Entire private house'),
    ('Room',      'Private room in host home'),
    ('Villa',     'Luxury countryside house'),
    ('Studio',    'Studio apartment');

INSERT INTO users (email, password_hash, first_name, last_name, phone, role, is_verified) VALUES
    ('john.smith@email.com',     '$2b$12$aA1bB2cC3dD4eE5fF6gG7u', 'John',    'Smith',    '+49301234567',  'host',  TRUE),
    ('emma.johnson@email.com',   '$2b$12$bB2cC3dD4eE5fF6gG7hH8u', 'Emma',    'Johnson',  '+351912345678', 'host',  TRUE),
    ('michael.brown@email.com',  '$2b$12$cC3dD4eE5fF6gG7hH8iI9u', 'Michael', 'Brown',    '+34612345678',  'host',  TRUE),
    ('sarah.davis@email.com',    '$2b$12$dD4eE5fF6gG7hH8iI9jJ0u', 'Sarah',   'Davis',    '+12125550101',  'guest', TRUE),
    ('james.wilson@email.com',   '$2b$12$eE5fF6gG7hH8iI9jJ0kK1u', 'James',   'Wilson',   '+447911123456', 'guest', FALSE),
    ('emily.taylor@email.com',   '$2b$12$fF6gG7hH8iI9jJ0kK1lL2u', 'Emily',   'Taylor',   '+61412345678',  'guest', TRUE),
    ('daniel.anderson@email.com','$2b$12$gG7hH8iI9jJ0kK1lL2mM3u', 'Daniel',  'Anderson', '+33612345678',  'guest', TRUE),
    ('olivia.martin@email.com',  '$2b$12$hH8iI9jJ0kK1lL2mM3nN4u', 'Olivia',  'Martin',   '+49151234567',  'guest', TRUE),
    ('william.thomas@email.com', '$2b$12$iI9jJ0kK1lL2mM3nN4oO5u', 'William', 'Thomas',   '+33712345678',  'both',  TRUE),
    ('sophia.jackson@email.com', '$2b$12$jJ0kK1lL2mM3nN4oO5pP6u', 'Sophia',  'Jackson',  '+34712345678',  'both',  TRUE);

INSERT INTO properties (host_id, type_id, title, description, address, city, country, price_per_night, max_guests, bedrooms, bathrooms) VALUES
    (1,  1, 'Modern Apartment in Mitte',         'Bright apartment in central Berlin',        'Unter den Linden 12',    'Berlin',    'Germany',         95.00, 2, 1, 1),
    (1,  1, 'Charming Apartment near Colosseum', 'Cozy apartment with historic views',        'Via Labicana 34',        'Rome',      'Italy',           110.00, 3, 1, 1),
    (2,  2, 'Sunny House in Alfama',             'Traditional house with a terrace',          'Rua das Flores 7',       'Lisbon',    'Portugal',        150.00, 5, 3, 2),
    (2,  2, 'Canal House in Jordaan',            'Classic Amsterdam canal-side house',        'Prinsengracht 88',       'Amsterdam', 'Netherlands',     180.00, 4, 2, 1),
    (3,  3, 'Private Room in Malasana',          'Cozy room in a vibrant neighbourhood',      'Calle del Pez 22',       'Madrid',    'Spain',            45.00, 1, 1, 1),
    (3,  5, 'City Studio near Old Town',         'Compact studio steps from city centre',     'Staromestske Nam. 5',    'Prague',    'Czech Republic',   60.00, 2, 0, 1),
    (9,  5, 'Cozy Studio in Le Marais',          'Stylish studio in the heart of Paris',      'Rue de Bretagne 14',     'Paris',     'France',           75.00, 2, 0, 1),
    (10, 4, 'Luxury Villa with Sea View',        'Exclusive villa with private pool',         'Avinguda del Mar 3',     'Barcelona', 'Spain',           320.00, 8, 4, 3);

INSERT INTO bookings (guest_id, property_id, check_in_date, check_out_date, total_price, status, created_at) VALUES
    (4,  1, '2026-01-10', '2026-01-15',  475.00,  'completed', '2025-12-20 10:15:00'),
    (5,  3, '2026-02-01', '2026-02-08', 1050.00,  'completed', '2026-01-10 14:30:00'),
    (6,  4, '2026-02-14', '2026-02-17',  540.00,  'completed', '2026-01-25 09:00:00'),
    (7,  5, '2026-03-05', '2026-03-10',  225.00,  'completed', '2026-02-15 11:45:00'),
    (8,  8, '2026-03-20', '2026-03-27', 2240.00,  'completed', '2026-02-28 16:20:00'),
    (9,  2, '2026-04-01', '2026-04-05',  440.00,  'completed', '2026-03-10 08:00:00'),
    (4,  6, '2026-04-10', '2026-04-12',  120.00,  'completed', '2026-03-20 13:30:00'),
    (5,  7, '2026-05-01', '2026-05-05',  300.00,  'confirmed', '2026-04-01 10:00:00'),
    (6,  1, '2026-05-10', '2026-05-15',  475.00,  'confirmed', '2026-04-05 12:00:00'),
    (7,  4, '2026-06-01', '2026-06-10', 1620.00,  'confirmed', '2026-04-10 15:45:00'),
    (10, 3, '2026-04-20', '2026-04-25',  750.00,  'cancelled', '2026-04-02 09:30:00'),
    (8,  2, '2026-05-15', '2026-05-18',  330.00,  'pending',   '2026-04-20 17:00:00');

INSERT INTO reviews (booking_id, rating, comment) VALUES
    (1,  5, 'Perfect location and very clean apartment. Highly recommend!'),
    (2,  4, 'Beautiful house with a lovely terrace. Great host.'),
    (3,  5, 'Amazing canal house, will definitely come back.'),
    (4,  3, 'Decent room but a bit noisy at night.'),
    (5,  5, 'Absolute luxury experience, worth every penny.'),
    (6,  4, 'Nice apartment in a great central location.'),
    (7,  2, 'Studio was much smaller than the photos suggested.');
