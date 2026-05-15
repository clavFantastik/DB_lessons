DROP TRIGGER IF EXISTS trg_prevent_invalid_booking_dates ON bookings;
DROP TRIGGER IF EXISTS trg_audit_booking_status ON bookings;
DROP TRIGGER IF EXISTS trg_log_review_insert ON reviews;
DROP TRIGGER IF EXISTS trg_validate_review_rating ON reviews;

CREATE TABLE property_stats (
    stat_id      SERIAL      PRIMARY KEY,
    property_id  INTEGER     NOT NULL UNIQUE REFERENCES properties(property_id) ON DELETE CASCADE,
    total_reviews INTEGER    NOT NULL DEFAULT 0,
    avg_rating    DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    last_review_at TIMESTAMP
);

CREATE TABLE review_audit_log (
    log_id      SERIAL      PRIMARY KEY,
    review_id   INTEGER     NOT NULL,
    booking_id  INTEGER     NOT NULL,
            rating      SMALLINT     NOT NULL,
    action      VARCHAR(10) NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION trg_fn_validate_booking_dates()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IN ('confirmed', 'pending') THEN
        IF EXISTS (
            SELECT 1
            FROM bookings
            WHERE property_id = NEW.property_id
              AND booking_id != COALESCE(NEW.booking_id, 0)
              AND status IN ('confirmed', 'pending')
              AND check_in_date < NEW.check_out_date
              AND check_out_date > NEW.check_in_date
        ) THEN
            RAISE EXCEPTION 'Booking dates overlap with existing booking for property %', NEW.property_id
            USING ERRCODE = '45008',
                  HINT = 'Please select different dates or property';
        END IF;
    END IF;

    IF NEW.check_out_date <= NEW.check_in_date THEN
        RAISE EXCEPTION 'Check-out date must be after check-in date'
        USING ERRCODE = '45005';
    END IF;

    IF NEW.check_in_date < CURRENT_DATE AND NEW.status IN ('confirmed', 'pending') THEN
        RAISE EXCEPTION 'Check-in date cannot be in the past for new bookings'
        USING ERRCODE = '45006';
    END IF;

    IF NEW.total_price <= 0 THEN
        RAISE EXCEPTION 'Total price must be greater than zero'
        USING ERRCODE = '45009';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_invalid_booking_dates
    BEFORE INSERT OR UPDATE ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_validate_booking_dates();

CREATE OR REPLACE FUNCTION trg_fn_audit_booking_status()
RETURNS TRIGGER AS $$
DECLARE
    v_user_email VARCHAR(255);
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO booking_audit (booking_id, old_status, new_status, changed_by)
        VALUES (NEW.booking_id, NULL, NEW.status,
                (SELECT email FROM users WHERE user_id = NEW.guest_id));
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status IS DISTINCT FROM NEW.status THEN
            INSERT INTO booking_audit (booking_id, old_status, new_status, changed_by)
            VALUES (NEW.booking_id, OLD.status, NEW.status,
                    (SELECT email FROM users WHERE user_id = NEW.guest_id));
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_booking_status
    AFTER INSERT OR UPDATE ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_audit_booking_status();

CREATE OR REPLACE FUNCTION trg_fn_update_property_stats()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO property_stats (property_id, total_reviews, avg_rating, last_review_at)
    VALUES (
        (SELECT property_id FROM bookings WHERE booking_id = NEW.booking_id),
        1,
        NEW.rating::DECIMAL(3,2),
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (property_id)
    DO UPDATE SET
        total_reviews = property_stats.total_reviews + 1,
        avg_rating = (
            SELECT AVG(rating)::DECIMAL(3,2)
            FROM reviews r
            JOIN bookings b ON r.booking_id = b.booking_id
            WHERE b.property_id = (SELECT property_id FROM bookings WHERE booking_id = NEW.booking_id)
        ),
        last_review_at = CURRENT_TIMESTAMP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_property_stats
    AFTER INSERT ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_update_property_stats();

CREATE OR REPLACE FUNCTION trg_fn_log_review()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO review_audit_log (review_id, booking_id, rating, action)
    VALUES (NEW.review_id, NEW.booking_id, NEW.rating, 'INSERT');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_review_insert
    AFTER INSERT ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_log_review();

CREATE OR REPLACE FUNCTION trg_fn_validate_review_rating()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.rating < 1 OR NEW.rating > 5 THEN
        RAISE EXCEPTION 'Rating must be between 1 and 5'
        USING ERRCODE = '45010';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM bookings b
        JOIN reviews r ON b.booking_id = r.booking_id
        WHERE r.review_id = COALESCE(NEW.review_id, 0)
    ) AND TG_OP = 'INSERT' THEN
        IF NOT EXISTS (
            SELECT 1
            FROM bookings
            WHERE booking_id = NEW.booking_id
              AND status = 'completed'
              AND guest_id IN (SELECT guest_id FROM bookings WHERE booking_id = NEW.booking_id)
        ) THEN
            RAISE EXCEPTION 'Review can only be added for completed bookings'
            USING ERRCODE = '45011';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_review_rating
    BEFORE INSERT OR UPDATE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_validate_review_rating();
