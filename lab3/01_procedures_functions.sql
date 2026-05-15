DROP FUNCTION IF EXISTS check_user_booking_activity(INTEGER);
DROP FUNCTION IF PROPERTY_EXISTS(INTEGER);
DROP PROCEDURE IF EXISTS add_booking_with_validation(INTEGER, INTEGER, DATE, DATE);
DROP PROCEDURE IF EXISTS update_property_rating(INTEGER);
DROP TABLE IF EXISTS booking_audit;

CREATE TABLE booking_audit (
    audit_id      SERIAL      PRIMARY KEY,
    booking_id    INTEGER     NOT NULL,
    old_status    booking_status,
    new_status    booking_status,
    changed_at    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by    VARCHAR(255)
);

CREATE FUNCTION property_exists(p_property_id INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM properties
        WHERE property_id = p_property_id
          AND is_active = TRUE
    );
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION check_user_booking_activity(p_user_id INTEGER)
RETURNS TABLE(
    total_bookings INTEGER,
    completed_bookings INTEGER,
    cancelled_bookings INTEGER,
    total_spent DECIMAL(10,2),
    last_booking_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::INTEGER AS total_bookings,
        COUNT(*) FILTER (WHERE status = 'completed')::INTEGER AS completed_bookings,
        COUNT(*) FILTER (WHERE status = 'cancelled')::INTEGER AS cancelled_bookings,
        COALESCE(SUM(total_price) FILTER (WHERE status = 'completed'), 0)::DECIMAL(10,2) AS total_spent,
        MAX(created_at)::DATE AS last_booking_date
    FROM bookings
    WHERE guest_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

CREATE PROCEDURE add_booking_with_validation(
    p_guest_id INTEGER,
    p_property_id INTEGER,
    p_check_in DATE,
    p_check_out DATE
) AS $$
DECLARE
    v_price_per_night DECIMAL(10,2);
    v_nights INTEGER;
    v_total_price DECIMAL(10,2);
    v_property_exists BOOLEAN;
    v_overlap_count INTEGER;
    v_guest_role user_role;
    v_guest_verified BOOLEAN;
BEGIN
    SELECT property_exists(p_property_id) INTO v_property_exists;

    IF NOT v_property_exists THEN
        RAISE EXCEPTION 'Property with ID % does not exist or is not active', p_property_id
        USING ERRCODE = '45001';
    END IF;

    SELECT price_per_night
    INTO v_price_per_night
    FROM properties
    WHERE property_id = p_property_id;

    SELECT role, is_verified
    INTO v_guest_role, v_guest_verified
    FROM users
    WHERE user_id = p_guest_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User with ID % does not exist', p_guest_id
        USING ERRCODE = '45002';
    END IF;

    IF v_guest_role NOT IN ('guest', 'both') THEN
        RAISE EXCEPTION 'User with ID % is not a guest', p_guest_id
        USING ERRCODE = '45003';
    END IF;

    IF NOT v_guest_verified THEN
        RAISE EXCEPTION 'User with ID % is not verified', p_guest_id
        USING ERRCODE = '45004';
    END IF;

    IF p_check_out <= p_check_in THEN
        RAISE EXCEPTION 'Check-out date must be after check-in date'
        USING ERRCODE = '45005';
    END IF;

    IF p_check_in < CURRENT_DATE THEN
        RAISE EXCEPTION 'Check-in date cannot be in the past'
        USING ERRCODE = '45006';
    END IF;

    v_nights := (p_check_out - p_check_in);

    SELECT COUNT(*)
    INTO v_overlap_count
    FROM bookings
    WHERE property_id = p_property_id
      AND status IN ('confirmed', 'pending')
      AND check_in_date < p_check_out
      AND check_out_date > p_check_in;

    IF v_overlap_count > 0 THEN
        RAISE EXCEPTION 'Property is not available for the selected dates'
        USING ERRCODE = '45007';
    END IF;

    v_total_price := v_nights * v_price_per_night;

    INSERT INTO bookings (guest_id, property_id, check_in_date, check_out_date, total_price, status)
    VALUES (p_guest_id, p_property_id, p_check_in, p_check_out, v_total_price, 'pending');

    RAISE NOTICE 'Booking created successfully. Total price: %, Nights: %', v_total_price, v_nights;
END;
$$ LANGUAGE plpgsql;

CREATE PROCEDURE update_property_rating(p_property_id INTEGER) AS $$
DECLARE
    v_avg_rating DECIMAL(3,2);
    v_review_count INTEGER;
BEGIN
    SELECT
        COALESCE(AVG(r.rating), 0)::DECIMAL(3,2),
        COUNT(*)::INTEGER
    INTO v_avg_rating, v_review_count
    FROM reviews r
    JOIN bookings b ON r.booking_id = b.booking_id
    WHERE b.property_id = p_property_id;

    IF v_review_count = 0 THEN
        RAISE NOTICE 'No reviews found for property %', p_property_id;
    ELSE
        RAISE NOTICE 'Property % updated - Average rating: % (based on % reviews)',
                     p_property_id, v_avg_rating, v_review_count;
    END IF;
END;
$$ LANGUAGE plpgsql;
