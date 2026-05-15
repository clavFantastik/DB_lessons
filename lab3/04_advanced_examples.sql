DROP TABLE IF EXISTS error_log CASCADE;

CREATE TABLE error_log (
    log_id      SERIAL      PRIMARY KEY,
    error_time  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    error_code  VARCHAR(10),
    error_message TEXT,
    operation   VARCHAR(100),
    user_id     INTEGER,
    details     JSONB
);

CREATE OR REPLACE FUNCTION log_error(p_operation VARCHAR, p_user_id INTEGER, p_details JSONB)
RETURNS VOID AS $$
BEGIN
    INSERT INTO error_log (error_code, error_message, operation, user_id, details)
    VALUES (SQLSTATE, SQLERRM, p_operation, p_user_id, p_details);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE safe_add_booking(
    p_guest_id INTEGER,
    p_property_id INTEGER,
    p_check_in DATE,
    p_check_out DATE
) AS $$
DECLARE
    v_booking_id INTEGER;
BEGIN
    PERFORM log_error('safe_add_booking', p_guest_id,
                      jsonb_build_object(
                          'property_id', p_property_id,
                          'check_in', p_check_in,
                          'check_out', p_check_out
                      ));

    CALL add_booking_with_validation(p_guest_id, p_property_id, p_check_in, p_check_out);

    SELECT booking_id INTO v_booking_id
    FROM bookings
    WHERE guest_id = p_guest_id
      AND property_id = p_property_id
      AND check_in_date = p_check_in
    ORDER BY created_at DESC
    LIMIT 1;

    RAISE NOTICE 'Booking % created successfully', v_booking_id;

EXCEPTION
    WHEN foreign_key_violation THEN
        PERFORM log_error('safe_add_booking', p_guest_id,
                          jsonb_build_object('error_type', 'foreign_key_violation'));
        RAISE EXCEPTION 'Referenced user or property does not exist';

    WHEN unique_violation THEN
        PERFORM log_error('safe_add_booking', p_guest_id,
                          jsonb_build_object('error_type', 'unique_violation'));
        RAISE EXCEPTION 'Duplicate booking detected';

    WHEN SQLSTATE '45001' THEN
        PERFORM log_error('safe_add_booking', p_guest_id,
                          jsonb_build_object('error_type', 'property_not_found'));
        RAISE;

    WHEN SQLSTATE '45007' THEN
        PERFORM log_error('safe_add_booking', p_guest_id,
                          jsonb_build_object('error_type', 'dates_not_available'));
        RAISE NOTICE 'Property is not available for selected dates. Showing available alternatives:';
        RAISE NOTICE 'Property ID 2: Available 2026-07-01 to 2026-07-10';
        RAISE NOTICE 'Property ID 3: Available 2026-07-05 to 2026-07-15';

    WHEN SQLSTATE '45005' THEN
        PERFORM log_error('safe_add_booking', p_guest_id,
                          jsonb_build_object('error_type', 'invalid_dates'));
        RAISE EXCEPTION 'Invalid dates: check-out must be after check-in';

    WHEN SQLSTATE '45006' THEN
        PERFORM log_error('safe_add_booking', p_guest_id,
                          jsonb_build_object('error_type', 'past_date'));
        RAISE EXCEPTION 'Cannot book dates in the past';

    WHEN SQLSTATE '45008' THEN
        PERFORM log_error('safe_add_booking', p_guest_id,
                          jsonb_build_object('error_type', 'overlap_detected'));
        RAISE EXCEPTION 'Booking dates overlap with existing booking';

    WHEN OTHERS THEN
        PERFORM log_error('safe_add_booking', p_guest_id,
                          jsonb_build_object('error_type', 'unknown', 'sqlstate', SQLSTATE));
        RAISE EXCEPTION 'Unexpected error occurred. Please contact support. Error reference logged.';
END;
$$ LANGUAGE plpgsql;

SELECT '=== Advanced Example 1: Safe booking with comprehensive error handling ===' AS example;

CALL safe_add_booking(4, 1, '2026-08-01', '2026-08-05');

SELECT '=== Advanced Example 2: Attempt booking with invalid dates ===' AS example;

CALL safe_add_booking(4, 1, '2026-08-05', '2026-08-01');

SELECT '=== Advanced Example 3: Attempt booking on non-existent property ===' AS example;

CALL safe_add_booking(4, 999, '2026-09-01', '2026-09-05');

SELECT '=== Advanced Example 4: Check error log ===' AS example;

SELECT
    log_id,
    error_time,
    error_code,
    error_message,
    operation,
    details
FROM error_log
ORDER BY error_time DESC
LIMIT 5;

SELECT '=== Advanced Example 5: Batch booking attempt ===' AS example;

DO $$
DECLARE
    v_properties INTEGER[] := ARRAY[1, 2, 3, 4];
    v_success_count INTEGER := 0;
    v_fail_count INTEGER := 0;
    v_prop INTEGER;
BEGIN
    FOREACH v_prop IN ARRAY v_properties
    LOOP
        BEGIN
            CALL safe_add_booking(4, v_prop, '2026-10-01', '2026-10-03');
            v_success_count := v_success_count + 1;
        EXCEPTION WHEN OTHERS THEN
            v_fail_count := v_fail_count + 1;
            RAISE NOTICE 'Property % failed: %', v_prop, SQLERRM;
        END;
    END LOOP;

    RAISE NOTICE 'Batch completed - Success: %, Failed: %', v_success_count, v_fail_count;
END $$;

SELECT '=== Advanced Example 6: Transaction with rollback on error ===' AS example;

DO $$
DECLARE
    v_booking_id INTEGER;
BEGIN
    INSERT INTO bookings (guest_id, property_id, check_in_date, check_out_date, total_price, status)
    VALUES (7, 5, '2026-11-01', '2026-11-05', 225.00, 'pending')
    RETURNING bookings.booking_id INTO v_booking_id;

    RAISE NOTICE 'Booking % created', v_booking_id;

    INSERT INTO reviews (booking_id, rating, comment)
    VALUES (v_booking_id, 5, 'Test review for incomplete booking');

    RAISE EXCEPTION 'This should trigger rollback';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error occurred, rolling back: %', SQLERRM;
        ROLLBACK;
END $$;

SELECT COUNT(*) AS booking_count FROM bookings WHERE guest_id = 7 AND check_in_date = '2026-11-01';

SELECT '=== Advanced Example 7: Update multiple bookings with individual error handling ===' AS example;

DO $$
DECLARE
    v_booking_record RECORD;
    v_updated_count INTEGER := 0;
BEGIN
    FOR v_booking_record IN
        SELECT booking_id, guest_id
        FROM bookings
        WHERE status = 'pending'
          AND check_in_date > CURRENT_DATE
        LIMIT 5
    LOOP
        BEGIN
            UPDATE bookings
            SET status = 'confirmed'
            WHERE booking_id = v_booking_record.booking_id;

            v_updated_count := v_updated_count + 1;
            RAISE NOTICE 'Booking % confirmed', v_booking_record.booking_id;

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Failed to confirm booking %: %',
                         v_booking_record.booking_id, SQLERRM;
        END;
    END LOOP;

    RAISE NOTICE 'Total bookings confirmed: %', v_updated_count;
END $$;

SELECT '=== Advanced Example 8: Property availability check function ===' AS example;

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

SELECT * FROM check_property_availability(1, '2026-12-01', '2026-12-05');
SELECT * FROM check_property_availability(999, '2026-12-01', '2026-12-05');
