CREATE OR REPLACE FUNCTION check_property_availability(
    p_property_id INTEGER,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    available BOOLEAN,
    reason TEXT
) AS $$
BEGIN
    IF NOT property_exists(p_property_id) THEN
        RETURN QUERY SELECT FALSE, 'Property not found or inactive'::TEXT;
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM bookings
        WHERE property_id = p_property_id
          AND status IN ('confirmed', 'pending')
          AND check_in_date < p_end_date
          AND check_out_date > p_start_date
    ) THEN
        RETURN QUERY SELECT FALSE, 'Property already booked for these dates'::TEXT;
        RETURN;
    END IF;

    IF p_start_date >= p_end_date THEN
        RETURN QUERY SELECT FALSE, 'Invalid date range'::TEXT;
        RETURN;
    END IF;

    IF p_start_date < CURRENT_DATE THEN
        RETURN QUERY SELECT FALSE, 'Start date is in the past'::TEXT;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'Property available'::TEXT;
END;
$$ LANGUAGE plpgsql;
