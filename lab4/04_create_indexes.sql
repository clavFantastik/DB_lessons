CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_lab4_bookings_complex_filter
ON bookings (status, check_in_date, total_price);

CREATE INDEX IF NOT EXISTS idx_lab4_bookings_created_at_desc
ON bookings (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_lab4_bookings_property_status_date
ON bookings (property_id, status, check_in_date);

CREATE INDEX IF NOT EXISTS idx_lab4_bookings_status_property_date
ON bookings (status, property_id, check_in_date);

CREATE INDEX IF NOT EXISTS idx_lab4_properties_title_trgm
ON properties USING gin (title gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_lab4_properties_description_trgm
ON properties USING gin (description gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_lab4_bookings_join_status_property
ON bookings (status, check_in_date, property_id);

CREATE INDEX IF NOT EXISTS idx_lab4_bookings_total_price
ON bookings (total_price);

ANALYZE users;
ANALYZE property_types;
ANALYZE properties;
ANALYZE bookings;
ANALYZE reviews;
