DROP INDEX IF EXISTS idx_lab4_bookings_complex_filter;
DROP INDEX IF EXISTS idx_lab4_bookings_created_at_desc;
DROP INDEX IF EXISTS idx_lab4_bookings_property_status_date;
DROP INDEX IF EXISTS idx_lab4_bookings_status_property_date;
DROP INDEX IF EXISTS idx_lab4_properties_title_trgm;
DROP INDEX IF EXISTS idx_lab4_properties_description_trgm;
DROP INDEX IF EXISTS idx_lab4_bookings_join_status_property;
DROP INDEX IF EXISTS idx_lab4_bookings_low_selectivity_status;
DROP INDEX IF EXISTS idx_lab4_bookings_total_price;
DROP INDEX IF EXISTS idx_properties_host;
DROP INDEX IF EXISTS idx_properties_city;
DROP INDEX IF EXISTS idx_bookings_guest;
DROP INDEX IF EXISTS idx_bookings_property;

ANALYZE users;
ANALYZE property_types;
ANALYZE properties;
ANALYZE bookings;
ANALYZE reviews;
